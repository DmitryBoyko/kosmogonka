extends SceneTree
const Walk = preload("res://scripts/finish_walk.gd")
var app: Node
var failures: Array[String]=[]
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 if not ok: failures.append(label); push_error(label)
func run():
 var display:=Node3D.new(); root.add_child(display)
 var trade=preload("res://scripts/plaza_trade_corner.gd")
 trade.lay_weapon(display,"Gun_Rifle",Vector3(0,1.156692,0),1.45,-.12)
 var weapon=display.get_child(0)
 var weapon_bounds=preload("res://scripts/loop_layout.gd").bounds(weapon,weapon.transform)
 check(absf(weapon_bounds.position.y-1.168692)<.001,"rifle rests on tabletop")
 check(weapon_bounds.size.y<.15,"rifle lies flat instead of standing upright")
 display.free()
 root.get_node("Profile").persistence_enabled=false
 app=load("res://scenes/main.tscn").instantiate(); app.test_mode=true; root.add_child(app)
 await process_frame; app.set_process(false); app.set_physics_process(false)
 app.planet=11; await app.start_level(); await app.begin_run(); app.distance=preload("res://scripts/course.gd").length_for(11); app.spawn_and_update(); app.finish_level()
 var bunker=app.finish.get_node("ExpeditionTradeCorner")
 app.finish_walk.avatar.global_position=bunker.to_global(Vector3(0,0,2))
 check(app.nearest_finish_shop()=="","bunker must not open suit shop")
 app.on_action("shop_nearest")
 check(app.state=="explore","removed interaction keeps exploration running")
 app.finish_walk.avatar.position=Vector3(0.,.08,9.)
 var patrol := Walk.patrol_collider(bunker,.56,2.2)
 patrol.position=Vector3(-7.5,0.,0.)
 await physics_frame
 check(not Walk.can_patrol(patrol,patrol,Vector3(-5.,0.,0.)),"patrol cannot cut through a bunker wall")
 patrol.position=Vector3(0.,0.,5.55)
 await physics_frame
 check(Walk.can_patrol(patrol,patrol,Vector3(0.,0.,2.5)),"patrol can use the open bunker doorway")
 patrol.free()
 var walker = app.finish_walk
 var resident := Walk.patrol_collider(walker,.57,2.6)
 resident.position=Vector3(0.,.08,6.)
 walker.avatar.position=Vector3(0.,.08,9.)
 walker.stick=Vector2(0.,-1.)
 for i in 48:
  await physics_frame
  walker.advance(1./60,false)
 check(walker.avatar.position.z>6.68,"hero stops at a visitor instead of walking through")
 resident.free()
 walker.stick=Vector2.ZERO
 var guard=bunker.get_node("BunkerGuard")
 for i in 840:
  var previous: Vector3=guard.position
  guard.advance(1./60,false)
  var velocity: Vector3=guard.position-previous
  if absf(velocity.x)>.001: check(guard.basis.z.dot(velocity.normalized())>.95,"guard faces patrol direction")
 for material in preload("res://scripts/robot_armor.gd").paints.values():
  check(material.get_shader_parameter("armor_map")!=null,"robot armor has panel texture")
 var spider=bunker.get_node("BunkerSpider")
 var on_table=false; var wall=false; var ground=false
 for i in 1800:
  spider.advance(1./60,false)
  check(spider.position.x<6. and spider.position.y<4.2,"spider inside bunker")
  on_table=on_table or (absf(spider.position.y-spider.tabletop)<.01 and spider.position.x<1.2)
  wall=wall or (spider.position.y>3. and spider.basis.y.x<-.95)
  ground=ground or spider.position.y<.01
 check(on_table and wall and ground,"spider visits table, floor and wall")
 var air=app.plaza_airshow
 check(air.scanners.size()==3,"one scanning robot on each of three platforms")
 for i in 240: app._process(1./60)
 check(app.plaza_dusk>.99,"plaza becomes nearly night")
 check(not app.sky_planet.visible,"no planet in plaza sky")
 check(app.surface_environment.sky.sky_material.get_shader_parameter("plaza_stars")!=null,"plaza uses starfield texture")
 check(app.finish.get_node("ShopBeacons").markers.size()==3,"three shop-only neon beacons")
 check(guard.joint_sparks.streaks.size()==6,"bounded robot spark effect")
 var spark_frames=0
 for i in 360:
  guard.joint_sparks.advance(1./60,true,false)
  if guard.joint_sparks.streaks.any(func(s):return s.visible):spark_frames+=1
 check(spark_frames>0 and spark_frames<100,"sparks occur as brief intermittent bursts")
 guard.joint_sparks.advance(.01,false,false)
 check(not guard.joint_sparks.streaks.any(func(s):return s.visible),"stationary robot does not spark")
 var beacons=app.finish.get_node("ShopBeacons")
 var before: float=beacons.materials[0].get_shader_parameter("clock")
 beacons.advance(.5,app.camera,false)
 check(beacons.materials[0].get_shader_parameter("clock")>before,"shop beacon animates the descending pulse")
 await app.start_level()
 await app.begin_run()
 for i in 240: app._process(1./60)
 check(app.plaza_dusk<.01,"race restores daylight")
 print("PLAZA REVISION: ",failures.size()," failures")
 app.free(); await process_frame; quit(0 if failures.is_empty() else 1)
