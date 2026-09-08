import SpriteKit

enum SpriteNames {
    static func name(for entity: Entity, frame: Int) -> String {
        let elapsed = entity.animElapsed(frame: frame)
        switch entity {
        case let player as Player:
            return playerName(player, elapsed: elapsed, frame: frame)
        case let rex as Rex:
            switch rex.animState {
            case .walk: return "rex.walk\(1 + (elapsed / 10) % 2)"
            case .leap: return "rex.leap"
            case .stun: return "rex.stun"
            case .roar: return "rex.roar"
            case .hurt: return (elapsed / 3) % 2 == 0 ? "rex.idle@flash" : "rex.idle"
            case .defeated: return (elapsed / 4) % 2 == 0 ? "rex.stun@flash" : "rex.stun"
            default: return "rex.idle"
            }
        case is Raptor:
            switch entity.animState {
            case .squished: return "raptor.squished"
            case .dead: return "raptor.walk1"
            default: return "raptor.walk\(1 + (elapsed / 10) % 2)"
            }
        case let anky as Anky:
            switch anky.animState {
            case .ball: return anky.isMovingBall ? "anky.ball\(1 + (elapsed / 4) % 2)" : "anky.ball1"
            case .ballWiggle: return (elapsed / 8) % 2 == 0 ? "anky.ball1" : "anky.walk1"
            case .dead: return "anky.ball1"
            default: return "anky.walk\(1 + (elapsed / 10) % 2)"
            }
        case is Ptero:
            switch entity.animState {
            case .fly: return "ptero.fly\(1 + (elapsed / 8) % 2)"
            case .squished: return "ptero.walk1"
            case .dead: return "ptero.fly1"
            default: return "ptero.walk\(1 + (elapsed / 10) % 2)"
            }
        case is Stego:
            return "stego.walk\(1 + (elapsed / 12) % 2)"
        case is Fireball:
            return "fireball.\(1 + (elapsed / 4) % 2)"
        case is Shuriken:
            return "shuriken\(1 + (elapsed / 3) % 2)"
        case let item as Item:
            switch item.powerUp {
            case .onigiri: return "item.onigiri"
            case .shurikenScroll: return "item.scroll"
            case .goldenKatana: return "item.katana"
            case .greenScroll: return "item.greenScroll"
            }
        default:
            return "fx.missing"
        }
    }

    private static func playerName(_ player: Player, elapsed: Int, frame: Int) -> String {
        let base = player.form == .small ? "ninja.small" : "ninja.big"
        var pose: String
        switch player.animState {
        case .dead: pose = "dead"
        case .jump: pose = "jump"
        case .skid: pose = "walk2"
        case .throwing: pose = player.form == .small ? "idle" : "throw"
        case .swordPlay: pose = "sword\(1 + (elapsed / 10) % 4)"
        case .walk:
            let hold = abs(player.velocity.x) > 100 ? 4 : 6
            pose = "walk\(1 + (elapsed / hold) % 2)"
        default: pose = "idle"
        }
        if player.isDead {
            return "ninja.small.dead"
        }
        var variant = ""
        if player.katanaActive {
            variant = "@gold\(1 + (frame / 4) % 3)"
        } else if player.form == .shuriken {
            variant = "@shuriken"
        }
        return "\(base).\(pose)\(variant)"
    }
}

@MainActor
final class EntityNodeSync {
    private let textures: TextureStore
    private let parent: SKNode
    private var nodes: [Int: SKSpriteNode] = [:]

    init(textures: TextureStore, parent: SKNode) {
        self.textures = textures
        self.parent = parent
    }

    func sync(world: GameWorld) {
        var seen = Set<Int>()
        update(world.player, world: world)
        seen.insert(world.player.id)
        for entity in world.entities {
            update(entity, world: world)
            seen.insert(entity.id)
        }
        for (id, node) in nodes where !seen.contains(id) {
            node.removeFromParent()
            nodes[id] = nil
        }
    }

    func removeAll() {
        nodes.values.forEach { $0.removeFromParent() }
        nodes.removeAll()
    }

    private func update(_ entity: Entity, world: GameWorld) {
        let name = SpriteNames.name(for: entity, frame: world.frame)
        let node: SKSpriteNode
        if let existing = nodes[entity.id] {
            node = existing
        } else {
            node = SKSpriteNode(texture: textures.texture(name), size: textures.size(of: name))
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            parent.addChild(node)
            nodes[entity.id] = node
        }
        if node.name != name {
            node.texture = textures.texture(name)
            node.size = textures.size(of: name)
            node.name = name
        }
        let upsideDown = entity.animState == .dead && !(entity is Player)
        node.anchorPoint = CGPoint(x: 0.5, y: upsideDown ? 1 : 0)
        node.xScale = entity.facing == .left ? -1 : 1
        node.yScale = upsideDown ? -1 : 1
        node.position = CGPoint(x: entity.rect.midX.rounded(), y: entity.rect.minY.rounded())
        node.zPosition = zPosition(for: entity)
        if let player = entity as? Player {
            node.isHidden = player.invulnerableFrames > 0 && (world.frame / 3) % 2 == 0 && world.isPlaying
        } else {
            node.isHidden = false
        }
    }

    private func zPosition(for entity: Entity) -> CGFloat {
        switch entity {
        case is Player: return 20
        case is Rex: return 12
        case is Shuriken, is Fireball: return 15
        case let item as Item: return item.isEmerging ? -5 : 8
        default: return 10
        }
    }
}
