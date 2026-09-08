enum Sfx: CaseIterable, Sendable {
    case jump
    case coin
    case stomp
    case kick
    case powerUp
    case hurt
    case die
    case blockBump
    case brickBreak
    case levelClear
    case oneUp
    case shuriken
    case checkpoint
    case bossHit
    case bossRoar
    case bossFall
    case uiTap
    case worldClear

    var recipe: ToneRecipe {
        switch self {
        case .jump:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.sweep(180, 620, 0.12, gain: 0.35)])
        case .coin:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.note(Note.b5, 0.06, gain: 0.3), .note(Note.e6, 0.3, gain: 0.3, release: 0.2)])
        case .stomp:
            return ToneRecipe(wave: .noise, segments: [.sweep(2000, 400, 0.06, gain: 0.4), .sweep(300, 90, 0.1, gain: 0.35)])
        case .kick:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.sweep(420, 180, 0.08, gain: 0.35)])
        case .powerUp:
            let notes = [Note.c5, Note.e5, Note.g5, Note.c6, Note.e6, Note.g6, Note.c7, Note.e7]
            return ToneRecipe(wave: .square(duty: 0.5), segments: notes.map { .note($0, 0.05, gain: 0.3) })
        case .hurt:
            return ToneRecipe(wave: .square(duty: 0.25), segments: [600, 450, 300, 200].map { .note($0, 0.1, gain: 0.35) })
        case .die:
            return ToneRecipe(wave: .triangle, segments: [
                .note(Note.g4, 0.15, gain: 0.5), .note(Note.e4, 0.15, gain: 0.5), .note(Note.c4, 0.4, gain: 0.5, release: 0.15),
                .rest(0.05), .note(Note.c3, 0.3, gain: 0.5, release: 0.15),
            ])
        case .blockBump:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.note(150, 0.06, gain: 0.4, release: 0.04)])
        case .brickBreak:
            return ToneRecipe(wave: .noise, segments: [.sweep(1200, 200, 0.18, gain: 0.4), .sweep(120, 60, 0.15, gain: 0.3)])
        case .levelClear:
            return ToneRecipe(wave: .triangle, segments: [
                .note(Note.c5, 0.12, gain: 0.5), .note(Note.e5, 0.12, gain: 0.5), .note(Note.g5, 0.12, gain: 0.5),
                .note(Note.c6, 0.12, gain: 0.5), .note(Note.g6, 0.5, gain: 0.5, release: 0.3),
            ])
        case .oneUp:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [Note.e5, Note.g5, Note.e6, Note.c6, Note.d6, Note.g6].map { .note($0, 0.08, gain: 0.3) })
        case .shuriken:
            return ToneRecipe(wave: .noise, segments: [.sweep(4000, 3000, 0.03, gain: 0.25), .sweep(1200, 900, 0.06, gain: 0.2)])
        case .checkpoint:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.note(Note.c6, 0.12, gain: 0.3), .note(Note.g6, 0.16, gain: 0.3, release: 0.1)])
        case .bossHit:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.sweep(110, 45, 0.3, gain: 0.5), .sweep(800, 200, 0.1, gain: 0.3)])
        case .bossRoar:
            return ToneRecipe(wave: .saw, segments: [.sweep(90, 70, 0.3, gain: 0.5), .sweep(75, 60, 0.3, gain: 0.5, release: 0.15)])
        case .bossFall:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.sweep(400, 40, 1.2, gain: 0.4, release: 0.3)])
        case .uiTap:
            return ToneRecipe(wave: .square(duty: 0.5), segments: [.note(880, 0.04, gain: 0.25)])
        case .worldClear:
            return ToneRecipe(wave: .triangle, segments: [
                .note(Note.c5, 0.1, gain: 0.5), .note(Note.c5, 0.1, gain: 0.5), .note(Note.c5, 0.1, gain: 0.5), .note(Note.c5, 0.25, gain: 0.5),
                .note(Note.e5, 0.25, gain: 0.5), .note(Note.g5, 0.25, gain: 0.5), .note(Note.c6, 0.7, gain: 0.5, release: 0.4),
            ])
        }
    }
}
