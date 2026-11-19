extends RefCounted
## Manual early start only shortens a settled intermission; spawning stays in main.
static func blocked_by(game: Node) -> String:
 if game.over:return "over"
 if game.resume_pending:return "resume"
 if game.enemy_drill or game.chain.kit_loaded:return "training"
 if game.user_paused:return "paused"
 if game.rewards.pending>0:return "reward"
 if game.edit_open or game.growth_open:return "configuration"
 if game.wave>=20:return "final"
 if game.remaining>0 or game.enemies.get_child_count()>0:return "combat"
 if not game.chain.active.is_empty() or not game.chain.pending.is_empty() or game.shots.get_child_count()>0 or not game.pending_flesh.is_empty():return "resolving"
 if game.wave>0 and not game.rewards.completed.has(game.wave):return "settlement"
 if game.rest<=0:return "queued"
 return ""
