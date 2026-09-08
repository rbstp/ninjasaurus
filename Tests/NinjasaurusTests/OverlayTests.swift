import SpriteKit
import XCTest
@testable import Ninjasaurus

final class OverlayTests: XCTestCase {
    @MainActor
    func testButtonsHitTestAndRelabel() {
        let textures = TextureStore()
        let overlay = OverlayNode(textures: textures, sceneSize: CGSize(width: 380, height: 176), title: "PAUSED",
                                  buttons: [("RESUME", .resume), ("MUSIC ON", .toggleMusic), ("MAP", .quit)])
        XCTAssertEqual(overlay.action(at: CGPoint(x: -104, y: -24)), .resume)
        XCTAssertEqual(overlay.action(at: CGPoint(x: 0, y: -24)), .toggleMusic)
        XCTAssertEqual(overlay.action(at: CGPoint(x: 104, y: -24)), .quit)
        XCTAssertEqual(overlay.action(at: CGPoint(x: 0, y: 60)), .none)
        XCTAssertEqual(overlay.action(at: CGPoint(x: -52, y: -24)), .none)
        XCTAssertEqual(overlay.action(at: CGPoint(x: 52, y: -24)), .none)
        XCTAssertEqual(overlay.action(at: CGPoint(x: -60, y: -24)), .resume)
        XCTAssertEqual(overlay.action(at: CGPoint(x: -46, y: -24)), .toggleMusic)
        overlay.setLabel("MUSIC OFF", for: .toggleMusic)
        let labels = overlay.children.compactMap { $0.children.first as? PixelTextNode }.map { $0.text }
        XCTAssertTrue(labels.contains("MUSIC OFF"))
        XCTAssertFalse(labels.contains("MUSIC ON"))
    }

    func testMusicSettingDefaultsToOnAndPersists() {
        let name = "NinjasaurusTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let store = ProgressStore(defaults: defaults)
        XCTAssertTrue(store.musicEnabled)
        store.musicEnabled = false
        XCTAssertFalse(ProgressStore(defaults: defaults).musicEnabled)
    }
}
