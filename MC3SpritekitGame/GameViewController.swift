//
//  GameViewController.swift
//  MC3SpritekitGame
//
//  Created by Waldi Febrianda on 21/07/21.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let skView = self.view as? SKView {
            let scene = MainMenuScene(size: CGSize(width: 2532, height: 1170))
            
            scene.scaleMode = .aspectFill
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            scene.size = self.view.bounds.size
            skView.presentScene(scene)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
