local function create_cascade_buffer(id, w, h)
	local color_params = {
		format     = 20, -- render.FORMAT_RGBA,
		width      = w,
		height     = h,
		min_filter = render.FILTER_NEAREST,
		mag_filter = render.FILTER_NEAREST,
		u_wrap     = render.WRAP_CLAMP_TO_EDGE,
		v_wrap     = render.WRAP_CLAMP_TO_EDGE
	}

	local depth_params = { 
		format        = render.FORMAT_DEPTH,
		width         = w,
		height        = h,
		min_filter    = render.FILTER_NEAREST,
		mag_filter    = render.FILTER_NEAREST,
		u_wrap        = render.WRAP_CLAMP_TO_EDGE,
		v_wrap        = render.WRAP_CLAMP_TO_EDGE
	}

	return render.render_target(id, {[render.BUFFER_COLOR_BIT] = color_params, [render.BUFFER_DEPTH_BIT] = depth_params })
end

local function get_frustum_points(inv_mvp)
	-- NDC coordinates
	local points = {
		-- near points
		vmath.vector4(-1, 1,-1,1),
		vmath.vector4( 1, 1,-1,1),
		vmath.vector4( 1,-1,-1,1),
		vmath.vector4(-1,-1,-1,1),
		-- far points
		vmath.vector4(-1, 1, 1,1),
		vmath.vector4( 1, 1, 1,1),
		vmath.vector4( 1,-1, 1,1),
		vmath.vector4(-1,-1, 1,1),
	}

	for k, v in pairs(points) do
		local p = inv_mvp * v
		
		p.x = p.x / p.w
		p.y = p.y / p.w
		p.z = p.z / p.w
		p.w = 1
		
		points[k] = p
	end

	return points
end

local function tov3(v4)
	return vmath.vector3(v4.x,v4.y,v4.z)
end

local function tov4(v3)
	return vmath.vector4(v3.x,v3.y,v3.z,1.0)
end

local function M_update(self, camera, camera_view, light_direction)

	local aspect         = camera.width / camera.height
	local limits         = {0, 0.3, 0.65, 1.0}
	local frustum_proj   = vmath.matrix4_perspective(camera.fov, aspect, camera.near, camera.far)
	local camera_inv_mvp = vmath.inv(frustum_proj * camera_view)

	for k, v in pairs(self.data) do
		local split_distance_prev = limits[k]
		local split_distance      = limits[k+1]
		local frustum_points_wp   = get_frustum_points(camera_inv_mvp)

		for i = 1, 4 do
			local ray_corner         = frustum_points_wp[i + 4] - frustum_points_wp[i]
			local ray_corner_near    = ray_corner * split_distance_prev
			local ray_corner_far     = ray_corner * split_distance
			frustum_points_wp[i + 4] = frustum_points_wp[i] + ray_corner_far;
			frustum_points_wp[i]     = frustum_points_wp[i] + ray_corner_near;
		end

		local frustum_center = vmath.vector4()
		for i = 1, 8 do
			frustum_center = frustum_center + frustum_points_wp[i]
		end
		frustum_center = frustum_center * (1/8)

		local far  = -1e10
		local near = 1e1

		local radius = 0
		for i = 1, 8 do
			local dist = vmath.length(frustum_points_wp[i] - frustum_center)
			radius     = math.max(radius, dist)
		end

		local extents_max = vmath.vector3(radius, radius, radius)
		local extents_min = extents_max * -1
		v.frustum_points  = frustum_points_wp
		v.frustum_center  = frustum_center

		local light_dir          = frustum_center - vmath.normalize(tov4(light_direction)) * -extents_min.z
		local light_view_matrix  = vmath.matrix4_look_at(tov3(light_dir), tov3(frustum_center), vmath.vector3(0,1,0))
		local cascade_extents    = extents_max - extents_min
		local light_ortho_matrix = vmath.matrix4_orthographic(extents_min.x, extents_max.x, extents_min.y, extents_max.y, 0, cascade_extents.z)

		v.view       = light_view_matrix
		v.projection = light_ortho_matrix

		local clip_dist = camera.far - camera.near
		self.limits[k]  = (camera.near + split_distance * clip_dist) * 1;
	end
end

local function M_set_near_far(self,c,near,far)
	self.data[c].near = near
	self.data[c].far  = far
end

local function M_get_view_matrix(self,c)
	return self.data[c].view
end

local function M_get_projection_matrix(self,c)
	return self.data[c].projection
end

local function M_get_num_cascades(self)
	return #self.data
end

local function M_get_buffer(self,c)
	return self.data[c].buffer
end

local function M_get_frustum_points(self,c)
	return self.data[c].frustum_points
end

local function M_get_frustum_center(self,c)
	return self.data[c].frustum_center
end

local function M_get_frustum_positions(self,c)
	return self.data[c].frustum_position
end

local function M_get_frustum_planes(self,c)
	return self.data[c].projection_planes
end

local function M_get_frustum_dir(self,c)
	return self.data[c].frustum_dir
end

local function M_get_cascade_limits(self)
	return self.limits
end

local M = {}
M.create = function(num_cascades, texture_size)
	local C = {
		data                   = {},
		limits                 = {},
		update                 = M_update,
		set_near_far           = M_set_near_far,
		get_buffer             = M_get_buffer,
		get_num_cascades       = M_get_num_cascades,
		get_view_matrix        = M_get_view_matrix,
		get_projection_matrix  = M_get_projection_matrix,
		get_frustum_points     = M_get_frustum_points,
		get_frustum_centers    = M_get_frustum_center,
		get_frustum_position   = M_get_frustum_positions,
		get_frustum_planes     = M_get_frustum_planes,
		get_frustum_directions = M_get_frustum_dir,
		get_cascade_limits     = M_get_cascade_limits
	}

	for i = 1, num_cascades do
		local cascade = {}

		cascade.buffer     = create_cascade_buffer("buffer_" .. i, texture_size, texture_size)
		cascade.projection = vmath.matrix4()
		cascade.view       = vmath.matrix4()
		cascade.near       = 0
		cascade.far        = 0
		
		table.insert(C.data, cascade)
	end
	
	return C
end

return M