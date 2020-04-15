local check_fall = function(pos, node)
	local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	local node_def = minetest.registered_nodes[below.name]
	if not node_def or node_def.walkable or (minetest.get_item_group(node.name, "float") ~= 0 and node_def.liquidtype ~= "none") then
		return false
	end
	if minetest.get_item_group(node.name, "falling_hanging_node") ~= 0 then
		local above = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
		local node_def = minetest.registered_nodes[above.name]
		if node_def and not node_def.walkable then
			return minetest.spawn_falling_node(pos)
		else
			return false
		end
	end
	local falling_sticky_node = minetest.get_item_group(node.name, "falling_sticky_node")
	if falling_sticky_node ~= 0 then
		local pos_table = {
			{x = pos.x - 1, y = pos.y, z = pos.z}, {x = pos.x + 1, y = pos.y, z = pos.z},
			{x = pos.x, y = pos.y + 1, z = pos.z},
			{x = pos.x, y = pos.y, z = pos.z - 1}, {x = pos.x, y = pos.y, z = pos.z + 1}
		}
		local connect = 0
		for _,v in ipairs(pos_table) do
			local node = minetest.get_node(v)
			local node_def = minetest.registered_nodes[node.name]
			if not node_def or node_def.walkable then
				connect = connect + 1
			end
		end
		if connect < falling_sticky_node then
			return minetest.spawn_falling_node(pos)
		else
			return false
		end
	end
end

minetest.register_on_placenode(function(pos, newnode)
	check_fall(pos, newnode)
end)

minetest.register_on_dignode(function(pos)
	local pos_table = {
		{x = pos.x - 1, y = pos.y, z = pos.z}, {x = pos.x + 1, y = pos.y, z = pos.z},
		{x = pos.x, y = pos.y - 1, z = pos.z}, {x = pos.x, y = pos.y + 1, z = pos.z},
		{x = pos.x, y = pos.y, z = pos.z - 1}, {x = pos.x, y = pos.y, z = pos.z + 1}
	}
	for _,v in ipairs(pos_table) do
		local node = minetest.get_node(v)
		check_fall(v, node)
	end
end)

minetest.register_on_punchnode(function(pos, node)
	check_fall(pos, node)
end)

if minetest.setting_getbool("enable_damage") then
	local falling_node = minetest.registered_entities["__builtin:falling_node"]
	local on_step_old = falling_node.on_step
	local on_step_add = function(self, dtime)
		local node = minetest.registered_nodes[self.node.name]
		local kill = false
		if minetest.get_item_group(node.name, "falling_kill_node") ~= 0 then
			local pos = self.object:getpos()
			local objs = minetest.get_objects_inside_radius(pos, 1)
			for _,v in ipairs(objs) do
				if v:is_player() and v:get_hp() ~= 0 then
					v:set_hp(0)
					kill = true
				end
			end
		else
			local damage = minetest.get_item_group(node.name, "falling_damage_node")
			if damage > 0 then
				local pos = self.object:getpos()
				local objs = minetest.get_objects_inside_radius(pos, 1)
				for _,v in ipairs(objs) do
					local hp = v:get_hp()
					if v:is_player() and hp ~= 0 then
						if not self.hit_players then
							self.hit_players = {}
						end
						local name = v:get_player_name()
						local hit = false
						for _,v in ipairs(self.hit_players) do
							if name == v then
								hit = true
							end
						end
						if not hit then
							table.insert(self.hit_players, name)
							hp = hp - damage
							if hp < 0 then
								hp = 0
							end
							v:set_hp(hp)
							if hp == 0 then
								kill = true
							end
						end
					end
				end
			end
		end
		-- This part is needed to play nicely with players bones.
		if kill then
			local pos = self.object:getpos()
			local pos = {x = pos.x, y = pos.y + 0.3, z = pos.z}
			if minetest.registered_nodes[self.node.name] then
				minetest.add_node(pos, self.node)
			end
			self.object:remove()
			minetest.check_for_falling(pos)
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
