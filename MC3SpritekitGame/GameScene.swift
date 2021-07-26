//
//  GameScene.swift
//  MC3SpritekitGame
//
//  Created by Waldi Febrianda on 21/07/21.
//

import SpriteKit

class GameScene: SKScene {
    let backgroundLayer = SKNode()
    
    let backgroundMovePointsPerSec: CGFloat = 200.0
    let lynn = LynnSprite(imageNamed: "Lynn Idle 1")
    var lynnIsInvincible = false
    let lynnAnimation: SKAction
    let playableRect: CGRect
    
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    let lynnMovePointsPerSec: CGFloat = 200.0
    var velocity: CGPoint = .zero
    let lynnRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let toxicMovePointsPerSec: CGFloat = 200.0
    var lives = 2
    var gameOver = false
    
    let toxicCollisionSound = SKAction.playSoundFileNamed("", waitForCompletion: false)
    let enemyCollisionSound = SKAction.playSoundFileNamed("", waitForCompletion: false)
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        var textures: [SKTexture] = []
        for i in 0...3 {
            textures.append(SKTexture(imageNamed: "Lynn\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        lynnAnimation = SKAction.repeatForever(
            SKAction.animate(with: textures, timePerFrame: 0.2))
        
        super.init(size: size)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    
    override func didMove(to view: SKView) {
        playBackgroundMusic(filename: "")
        
        backgroundLayer.zPosition = -1
        addChild(backgroundLayer)
  
        for i in 0...1 {
            let background = backgroundNode()
            background.size = CGSize(width: frame.maxX, height: frame.maxY)
            background.position = CGPoint(x: size.width/2,
                                              y: size.height/2)
            background.anchorPoint = CGPoint(x: 0.0, y: 0.0)
            background.name = "Starting page.jpg"
            background.zPosition = -1
            backgroundLayer.addChild(background)
        }
        
        lynn.zPosition = -1
        lynn.position = CGPoint(x: 10, y: 10)
        backgroundLayer.addChild(lynn)
        
//        run(SKAction.repeatForever(
//            SKAction.sequence([SKAction.run(spawnEnemy),
//                               SKAction.wait(forDuration: 2.0)])))
//
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnToxic),
                               SKAction.wait(forDuration: 1.0)])))
        
    }
    
    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: backgroundLayer)
            sceneTouched(touchLocation: touchLocation)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: backgroundLayer)
            sceneTouched(touchLocation: touchLocation)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: backgroundLayer)
        }
    }
    #else
    override func mouseDown(with event: NSEvent) {
        let touchLocation = event.location(in: backgroundLayer)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        let touchLocation = theEvent.location(in: backgroundLayer)
        sceneTouched(touchLocation: touchLocation)
    }
    #endif
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        moveSprite(lynn, velocity: velocity)
        rotateSprite(lynn, direction: velocity, rotateRadiansPerSec: lynnRotateRadiansPerSec)
        
        boundsCheckLynn()
        moveTrain()
        //moveBackground()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You lose!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func moveSprite(_ sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveLynnToward(location: CGPoint) {
        startLynnAnimation()
        let offset = location - lynn.position
        let length = offset.length()
        let direction = offset / length
        velocity = direction * lynnMovePointsPerSec
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        moveLynnToward(location: touchLocation)
    }
    
    func boundsCheckLynn() {
        let bottomLeft = backgroundLayer.convert(CGPoint(x: 0, y: playableRect.minY), from: self)
        let topRight = backgroundLayer.convert(CGPoint(x: size.width, y: playableRect.maxY), from: self)
        
        if lynn.position.x <= bottomLeft.x {
            lynn.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if lynn.position.x >= topRight.x {
            lynn.position.x = topRight.x
            velocity.x = -velocity.x
            
        }
        if lynn.position.y <= bottomLeft.y {
            lynn.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if lynn.position.y >= topRight.y {
            lynn.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func rotateSprite(_ sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnGula() {
        let gula = GulaSprite(imageNamed: "Gula0")
        gula.name = "Gula Idle 1"
        gula.zPosition = 1
        let gulaScenePos = CGPoint(
            x: size.width + gula.size.width / 2,
            y: CGFloat.random(
                min: playableRect.minY + gula.size.height/2,
                max: playableRect.maxY - gula.size.height/2
            )
        )
        gula.position = backgroundLayer.convert(gulaScenePos, from: self)
        backgroundLayer.addChild(gula)

        let actionMove = SKAction.moveBy(x: -size.width - gula.size.width, y: 0, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        gula.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startLynnAnimation() {
        if lynn.action(forKey: "animation") == nil {
            lynn.run(SKAction.repeatForever(lynnAnimation), withKey: "animation")
        }
    }
    
    func stopLynnAnimation() {
        lynn.removeAction(forKey: "animation")
    }
    
    func spawnToxic() {
        let toxic = ToxicSprite(imageNamed: "Racun0")
        toxic.name = "racun"
        toxic.zPosition = 1
        
        let toxicScenePos = CGPoint(
            x: CGFloat.random(min: playableRect.minX, max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY, max: playableRect.maxY)
        )
        toxic.position = backgroundLayer.convert(toxicScenePos, from: self)
        toxic.setScale(0)
        backgroundLayer.addChild(toxic)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        
        let leftWiggle = SKAction.rotate(byAngle: π / 8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        toxic.run(SKAction.sequence(actions))
    }
    
    func lynnHitToxic(toxic: ToxicSprite) {
        if toxic.wasTurned {
            return
        }
        toxic.wasTurned = true
        toxic.name = "train"
        
        run(toxicCollisionSound)
        toxic.removeAllActions()
        toxic.setScale(1)
        toxic.zRotation = 0
        
        let turnGreenAction = SKAction.colorize(with: .green, colorBlendFactor: 1.0, duration: 0.2)
        toxic.run(turnGreenAction)
    }
    
    func lynnHitGula(gula: GulaSprite) {
        gula.removeFromParent()
        run(enemyCollisionSound)
        loseToxic()
        lives -= 1

        lynnIsInvincible = true

        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let hideAction = SKAction.run {
            self.lynn.isHidden = false
            self.lynnIsInvincible = false
        }
        lynn.run(SKAction.sequence([blinkAction, hideAction]))
    }
    
    func checkCollisions() {
        if lynnIsInvincible {
            return
        }
        
        var hitToxic: [ToxicSprite] = []
        backgroundLayer.enumerateChildNodes(withName: "Toxic") { (node, _) in
            if let toxic = node as? ToxicSprite {
                if toxic.frame.intersects(self.lynn.frame) {
                    hitToxic.append(toxic)
                }
            }
        }
        for toxic in hitToxic {
            lynnHitToxic(toxic: toxic)
        }
        
        var hitGula: [GulaSprite] = []
        backgroundLayer.enumerateChildNodes(withName: "Gula Idle 1") { (node, _) in
            if let gula = node as? GulaSprite {
                let gulaFrame = CGRect(origin: node.frame.origin, size: CGSize(width: 20, height: 20))
                if gulaFrame.intersects(self.lynn.frame) {
                    hitGula.append(gula)
                }
            }
        }
        for gula in hitGula {
            lynnHitGula(gula: gula)
        }
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = lynn.position
        
        backgroundLayer.enumerateChildNodes(withName: "train") { (node, _) in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.toxicMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        
        if trainCount >= 30 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseToxic() {
        var loseCount = 0
        backgroundLayer.enumerateChildNodes(withName: "train") { (node, stop) in
            var randomSpot = node.position
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotate(byAngle: π*4, duration: 1.0),
                        SKAction.move(to: randomSpot, duration: 1.0),
                        SKAction.scale(to: 0, duration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                ]))
            loseCount += 1
            if loseCount >= 2 {
                stop.pointee = true
            }
        }
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = .zero
        backgroundNode.name = "bg game lev 1"
        
        let background1 = SKSpriteNode(imageNamed: "bg game lev 1")
        background1.size = self.frame.size
        background1.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background1.position = CGPoint(x: 0.5, y: 0.5)
        backgroundNode.addChild(background1)
        
//        let background2 = SKSpriteNode(imageNamed: "bg game lev 1")
//        background1.size = self.frame.size
//        background2.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        background1.position = CGPoint(x: 0.5, y: 0.5)
//        backgroundNode.addChild(background2)
//
//        backgroundNode.size = CGSize(
//            width: background1.size.width + background2.size.width,
//            height: background1.size.height)
        
        return backgroundNode
    }
    
//    func moveBackground() {
//        let backgroundVelocity = CGPoint(x: -self.backgroundMovePointsPerSec, y: 0)
//        let amountToMove = backgroundVelocity * CGFloat(dt)
//        backgroundLayer.position += amountToMove
//
//        backgroundLayer.enumerateChildNodes(withName: "bg game lev 1") { (node, _) in
//            if let background = node as? SKSpriteNode {
//                let backgroundScreenPos = self.backgroundLayer.convert(background.position, to: self)
//                if backgroundScreenPos.x <= -background.size.width {
//                    background.position = CGPoint(
//                        x: background.position.x + background.size.width * 2,
//                        y: background.position.y)
//                }
//            }
//        }
//    }
}


    

    

