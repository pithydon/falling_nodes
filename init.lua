minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if minetest.get_item_group(newnode.name, "falling_hanging_node") ~= 0 then
		local above = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
		local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
		if not minetest.registered_nodes[above.name].walkable and not minetest.registered_nodes[below.name].walkable then
			minetest.remove_node(pos)
			spawn_falling_node(pos, newnode)
		end
	elseif minetest.get_item_group(newnode.name, "falling_sticky_node") ~= 0 then
		local pos_table = {
			{x = pos.x - 1, y = pos.y, z = pos.z}, {x = pos.x + 1, y = pos.y, z = pos.z},
			{x = pos.x, y = pos.y - 1, z = pos.z}, {x = pos.x, y = pos.y + 1, z = pos.z},
			{x = pos.x, y = pos.y, z = pos.z - 1}, {x = pos.x, y = pos.y, z = pos.z + 1}
		}
		local fall = true
		for _,v in ipairs(pos_table) do
			local node = minetest.get_node(v)
			if minetest.registered_nodes[node.name].walkable then
				fall = false
			end
		end
		if fall then
			minetest.remove_node(pos)
			spawn_falling_node(pos, newnode)
		end
	end
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
	local under = {x = pos.x, y = pos.y - 1, z = pos.z}
	local node = minetest.get_node(under)
	if minetest.get_item_group(node.name, "falling_hanging_node") ~= 0 then
		minetest.remove_node(under)
		spawn_falling_node(under, node)
	end
	local above = {x = pos.x, y = pos.y + 1, z = pos.z}
	local node = minetest.get_node(above)
	if minetest.get_item_group(node.name, "falling_hanging_node") ~= 0 then
		local above_above = {x = pos.x, y = pos.y + 2, z = pos.z}
		local above_node = minetest.get_node(above_above)
		if not minetest.registered_nodes[above_node.name].walkable then
			minetest.remove_node(above)
			spawn_falling_node(above, node)
		end
	end
	local pos_table = {
		{x = pos.x - 1, y = pos.y, z = pos.z}, {x = pos.x + 1, y = pos.y, z = pos.z},
		under, above,
		{x = pos.x, y = pos.y, z = pos.z - 1}, {x = pos.x, y = pos.y, z = pos.z + 1}
	}
	local node_table = {}
	for i,v in ipairs(pos_table) do
		node_table[i] = minetest.get_node(v)
	end
	local falling_nodes = {}
	for i,v in ipairs(node_table) do
		if minetest.get_item_group(v.name, "falling_sticky_node") ~= 0 then
			table.insert(falling_nodes, pos_table[i])
		end
	end
	for _,v in ipairs(falling_nodes) do
		local pos_table = {
			{x = v.x - 1, y = v.y, z = v.z}, {x = v.x + 1, y = v.y, z = v.z},
			{x = v.x, y = v.y - 1, z = v.z}, {x = v.x, y = v.y + 1, z = v.z},
			{x = v.x, y = v.y, z = v.z - 1}, {x = v.x, y = v.y, z = v.z + 1}
		}
		local fall = true
		for _,v in ipairs(pos_table) do
			local node = minetest.get_node(v)
			if minetest.registered_nodes[node.name].walkable then
				fall = false
			end
		end
		if fall then
			local node = minetest.get_node(v)
			minetest.remove_node(v)
			spawn_falling_node(v, node)
		end
	end
end)

if minetest.setting_getbool("enable_damage") then
	local falling_node = minetest.registered_entities["__builtin:falling_node"]
	local on_step_old = falling_node.on_step
	local on_step_add = function(self, dtime)
		local node = minetest.registered_nodes[self.node.name]
		if minetest.get_item_group(node.name, "falling_kill_node") ~= 0 then
			local pos = self.object:getpos()
			local objs = minetest.get_objects_inside_radius(pos, 1)
			for _,v in ipairs(objs) do
				if v:is_player() then
					v:set_hp(0)
				end
			end
		end
	end
	local on_step_table = {on_step_old, on_step_add}
	local on_step_new = table.copy(on_step_table)
	falling_node.on_step = function(self, dtime)
		for _,v in ipairs(on_step_new) do
			v(self, dtime)
		end
	end
end