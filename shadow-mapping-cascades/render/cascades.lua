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
		vmath.vector4(-1,-1,-1,1),vmath.vector4(1,-1,-1,1),vmath.vector4(1,1,-1,1),vmath.vector4(-1,1,-1,1),
		-- far points
		vmath.vector4(-1,-1,1,1),vmath.vector4(1,-1,1,1),vmath.vector4(1,1,1,1),vmath.vector4(-1,1,1,1),
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

local function get_ortho_planes(frustum_points, inv_light_matrix)
	local max_v =  1e10
	local min_x =  max_v
	local max_x = -max_v
	local min_y =  max_v
	local max_y = -max_v
	local min_z =  max_v
	local max_z = -max_v

	for k, v in pairs(frustum_points) do
		local p = inv_light_matrix * v
		min_x   = math.min(min_x, p.x)
		min_y   = math.min(min_y, p.y)
		min_z   = math.min(min_z, p.z)
		max_x   = math.max(max_x, p.x)
		max_y   = math.max(max_y, p.y)
		max_z   = math.max(max_z, p.z)
	end

	return { l = min_x, r = max_x, b = min_y, t = max_y, n = min_z, f = max_z }
end

local M = {}

local function M_update(self, camera, camera_view, light_direction)
	local aspect = camera.width / camera.height
	local limits = {camera.near, camera.far / 10, camera.far / 5, camera.far}
	local tan_half_hfov = math.tan(camera.fov)
	local tan_half_vfov = math.tan(camera.fov * aspect)
	local inv_view = vmath.inv(camera_view)

	--[[
	for k, v in pairs(self.data) do
		local xn = limits[k]     * tan_half_hfov
		local xf = limits[k + 1] * tan_half_hfov
		local yn = limits[k]     * tan_half_vfov
		local yf = limits[k + 1] * tan_half_vfov

		local frustum_corners = {
			vmath.vector4( xn,  yn, limits[k], 1.0),
			vmath.vector4(-xn,  yn, limits[k], 1.0),
			vmath.vector4( xn, -yn, limits[k], 1.0),
			vmath.vector4(-xn, -yn, limits[k], 1.0),

			vmath.vector4( xf,  yf, limits[k + 1], 1.0),
			vmath.vector4(-xf,  yf, limits[k + 1], 1.0),
			vmath.vector4( xf, -yf, limits[k + 1], 1.0),
			vmath.vector4(-xf, -yf, limits[k + 1], 1.0),
		}

		local z_min = 1e10
		local z_max = -z_min

		local frustum_center  = vmath.vector4()

		for k,v in pairs(frustum_corners) do
			local vx_world = inv_view * v
			frustum_corners[k] = vx_world

			frustum_center = frustum_center + vx_world
			z_min          = math.min(z_min, vx_world.z)
			z_max          = math.max(z_max, vx_world.z)
		end

		frustum_center  = frustum_center * (1/8)

		local lpos_dist = z_max - z_min
		local lpos_dir  = vmath.vector4(light_direction.x,light_direction.y,light_direction.z,0) * lpos_dist
		local lpos      = frustum_center + lpos_dir

		local langle_x = math.acos(light_direction.z)
		local langle_y = math.asin(light_direction.x)
		local view_inv = vmath.matrix4_rotation_y(langle_y) * vmath.matrix4_rotation_x(langle_x)
		view_inv.m03   = -lpos.x
		view_inv.m13   = -lpos.y
		view_inv.m23   = -lpos.z

		v.view       = vmath.inv(view_inv)
		v.projection = get_ortho_matrix(frustum_corners, view_inv)
		v.frustum_points = frustum_corners
		v.frustum_center = frustum_center
	end
	--]]

	for k, v in pairs(self.data) do
		local frustum_proj    = vmath.matrix4_perspective(camera.fov, aspect, v.near, v.far)
		local frustum_inv_mvp = vmath.inv(frustum_proj * inv_view)
		
		local frustum_center  = vmath.vector4()
		local frustum_points  = get_frustum_points(frustum_inv_mvp)

		local z_min = 1e10
		local z_max = -z_min

		for _, p in pairs(frustum_points) do
			frustum_center = frustum_center + p
			z_min          = math.min(z_min, p.z)
			z_max          = math.max(z_max, p.z)
		end

		frustum_center  = frustum_center * (1/8)
		local lpos_dist = z_max - z_min
		local lpos_dir  = vmath.vector4(light_direction.x,light_direction.y,light_direction.z,0) * lpos_dist
		local lpos      = frustum_center + lpos_dir
		
		local langle_x = math.acos(light_direction.z)
		local langle_y = math.asin(light_direction.x)
		local view_inv = vmath.matrix4_rotation_y(langle_y) * vmath.matrix4_rotation_x(langle_x)
		view_inv.m03   = -lpos.x
		view_inv.m13   = -lpos.y
		view_inv.m23   = -lpos.z

		local planes = get_ortho_planes(frustum_points, view_inv)

		v.projection_planes = planes
		v.view              = vmath.inv(view_inv)
		v.projection        = vmath.matrix4_orthographic(planes.l, planes.r, planes.b, planes.t, planes.n, planes.f)
		v.frustum_points    = frustum_points
		v.frustum_center    = frustum_center
		v.frustum_position  = lpos
		v.frustum_dir       = lpos_dir
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

M.create = function(num_cascades, texture_size)
	local C = {
		data                   = {},
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
		get_frustum_directions = M_get_frustum_dir
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