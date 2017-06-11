//
//  GameScene.swift
//  LoudBird
//
//  Created by Ryan Moughan on 7/12/16.
//  Copyright (c) 2016 RMC. All rights reserved.
//
//


import SpriteKit
import AudioKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var startGame = true
    var startGameLabel = SKLabelNode()
    
    var bird = SKSpriteNode()
    var background = SKSpriteNode()
    var pipe1 = SKSpriteNode()
    var pipe2 = SKSpriteNode()
    let gap = SKNode()
    let sky = SKNode()
    let ground = SKNode()
    
    var gameOver = false
    var score = 0
    var scoreLabel = SKLabelNode()
    var gameOverLabel = SKLabelNode()
    var labelContainer = SKLabelNode()
    
    enum ColliderType: UInt32 {
        
        case bird = 1
        case object = 2
        case gap = 4
    }
    
    var environment = SKSpriteNode()
    
    let noteFrequencies = [16.35, 18.35, 20.60, 21.83, 24.50, 27.50, 30.87]
    let optFrequencies = [17.32, 19.45, 23.12, 25.96, 29.14]
    let regNotesArray = ["C", "D", "E", "F", "G", "A", "B"]
    let sharpNotesArray = ["C#", "D#", "F#", "G#", "A#"]
    let flatNotesArray = ["Db", "Eb", "Gb", "Ab", "Bb"]
    var note: String?
    let maxFreq: Double = 800
    let minFreq: Double = 100
    
    var cheat1Active = false
    var cheat2Active = false
    var cheat3Active = false
    
    func makeBG() {
        
        let bgTexture = SKTexture(imageNamed: "bg.png")
        
        let moveBG = SKAction.moveByX(-bgTexture.size().width, y: 0, duration: 9)
        let replaceBG = SKAction.moveByX(bgTexture.size().width, y: 0, duration: 0)
        let bgSequence = SKAction.sequence([moveBG,replaceBG])
        let moveBGForever = SKAction.repeatActionForever(bgSequence)
        
        //Creates treadmill of three background images for infinite sequence
        for i in 0 ..< 3 {
            
            background = SKSpriteNode(texture: bgTexture)
            
            background.position = CGPoint(x: bgTexture.size().width/2 + bgTexture.size().width * CGFloat(i), y: CGRectGetMidY(self.frame))
            
            background.size.height = self.frame.height
            
            background.zPosition = -5
            
            background.runAction(moveBGForever)
            
            environment.addChild(background)
        }
        
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        let bgTexture = SKTexture(imageNamed: "bg.png")
        let bg = SKSpriteNode(texture: bgTexture)
        bg.size.height = self.frame.height
        bg.zPosition = -5
        bg.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        self.addChild(bg)
        
        startGameLabel.fontName = "Chalkboard"
        startGameLabel.text = "Start"
        startGameLabel.fontSize = 60
        startGameLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        self.addChild(startGameLabel)
        
        let mic = AKMicrophone()
        let tracker = AKFrequencyTracker.init(mic, minimumFrequency: minFreq, maximumFrequency: maxFreq)
        let nyquistFreq: Double = 1/maxFreq
        
        AudioKit.output = tracker
        AudioKit.start()
        
        codeLoop(every: nyquistFreq) {
            
            //Checks to see if the amplitude is strong enough to be a note
            if tracker.amplitude > 0.1 {
                
                //Converts the current frequency into its base octave form using the power of 2
                var frequency = Float(tracker.frequency)
                while (frequency > Float(self.noteFrequencies[self.noteFrequencies.count-1])) {
                    frequency = frequency / 2.0
                }
                while (frequency < Float(self.noteFrequencies[0])) {
                    frequency = frequency * 2.0
                }
                
                //Uses the for loop to iterate through each regular frequency and sets the minDistance equal to the smallest difference (the note playing)
                var minDistance: Float = 10000.0
                var index = 0
                
                for i in 0..<self.noteFrequencies.count {
                    let distance = fabsf(Float(self.noteFrequencies[i]) - frequency)
                    if distance < minDistance{
                        index = i
                        minDistance = distance
                    }
                }
                
                //Uses the for loop to iterate through each sharp/flat frequency and sets the optMinDistance equal to the smallest difference (the note playing)
                var optMinDistance: Float = 10000.0
                var optIndex = 0
        
                for i in 0..<self.optFrequencies.count {
                    let optDistance = fabsf(Float(self.optFrequencies[i]) - frequency)
                    if optDistance < optMinDistance{
                        optIndex = i
                        optMinDistance = optDistance
                    }
                }
                
                //Determines the octave by taking the log2 of the fraction between the current and base frequencies
                let octave = Int(log2f(Float(tracker.frequency) / frequency))
                
                //Choooses between the regular notes and flats/sharps by checking the minDist for each and seeing which is less
                if optMinDistance < minDistance {
                    
                    self.note = "\(self.sharpNotesArray[optIndex])\(octave)/\(self.flatNotesArray[optIndex])\(octave)"
                    
                } else {
                    
                    self.note = "\(self.regNotesArray[index])\(octave)"
                }
            }
            
            if self.note == "C4" {
                
                self.musicBegan()
            }
            
            if self.note == "F#4/Gb4" {
                
                self.cheat1Began()
            }
            
            if self.note == "E4" {
                
                self.cheat2Began()
            }
            
            if self.note == "A3" {
                
                self.cheat3Began()
            }
            
            if self.note == "D3" {
                
                self.cheat4Began()
            }
            
            self.note = ""
        }
    }
    
    func createEnvironment() {
        
        self.physicsWorld.contactDelegate = self
        
        self.addChild(environment)
        
        self.addChild(labelContainer)
        
        makeBG()
        
        scoreLabel.fontName = "Chalkboard"
        scoreLabel.fontSize = 60
        scoreLabel.text = "0"
        scoreLabel.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.size.height - 70)
        scoreLabel.zPosition = 5
        self.addChild(scoreLabel)
        
        createBird()
        
        ground.position = CGPointMake(0, 0)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, 1))
        ground.physicsBody!.dynamic = false
        
        ground.physicsBody!.categoryBitMask = ColliderType.object.rawValue
        ground.physicsBody!.contactTestBitMask = ColliderType.object.rawValue
        ground.physicsBody!.collisionBitMask = ColliderType.object.rawValue
        
        createSky()
        
        self.addChild(ground)
        
        _ = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(GameScene.createPipes), userInfo: nil, repeats: true)
    }
    
    func createSky() {
        
        sky.position = CGPointMake(0, self.frame.size.height)
        sky.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, 1))
        sky.physicsBody!.dynamic = false
        self.addChild(sky)
    }
    
    func createPipes() {
        
        let gapHeight = bird.size.height * 3.5
        
        let gapRandom = arc4random() % UInt32(self.frame.size.height / 2)
        let pipeOffset = CGFloat(gapRandom) - self.frame.size.height / 4
        
        let movePipes = SKAction.moveByX(-self.frame.size.width * 2, y: 0, duration: NSTimeInterval(self.frame.size.width / 100))
        let removePipes = SKAction.removeFromParent()
        let pipeSequence = SKAction.sequence([movePipes, removePipes])
        
        let pipeTexture1 = SKTexture(imageNamed: "pipe1.png")
        pipe1 = SKSpriteNode(texture: pipeTexture1)
        pipe1.position = CGPointMake(CGRectGetMidX(self.frame) + self.frame.size.width, CGRectGetMidY(self.frame) + pipeTexture1.size().height/2 + gapHeight/2 + pipeOffset)
        pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipeTexture1.size())
        pipe1.physicsBody!.dynamic = false
        
        if cheat1Active == true {
            
            pipe1.physicsBody!.categoryBitMask = ColliderType.bird.rawValue
            
        } else {
        
            pipe1.physicsBody!.categoryBitMask = ColliderType.object.rawValue
        }
        pipe1.physicsBody!.collisionBitMask = ColliderType.object.rawValue
        pipe1.physicsBody!.contactTestBitMask = ColliderType.object.rawValue
        pipe1.runAction(pipeSequence)
        
        let pipeTexture2 = SKTexture(imageNamed: "pipe2.png")
        pipe2 = SKSpriteNode(texture: pipeTexture2)
        pipe2.position = CGPointMake(CGRectGetMidX(self.frame) + self.frame.size.width, CGRectGetMidY(self.frame) - pipeTexture2.size().height/2 - gapHeight/2 + pipeOffset)
        pipe2.physicsBody = SKPhysicsBody(rectangleOfSize: pipeTexture2.size())
        pipe2.physicsBody!.dynamic = false
        
        if cheat1Active == true {
            
            pipe2.physicsBody!.categoryBitMask = ColliderType.bird.rawValue
            
        } else {
        
            pipe2.physicsBody!.categoryBitMask = ColliderType.object.rawValue
        }
        
        pipe2.physicsBody!.collisionBitMask = ColliderType.object.rawValue
        pipe2.physicsBody!.contactTestBitMask = ColliderType.object.rawValue
        pipe2.runAction(pipeSequence)
        
        environment.addChild(pipe1)
        environment.addChild(pipe2)
        
        let gap = SKNode()
        gap.position = CGPoint(x: CGRectGetMidX(self.frame) + self.frame.size.width, y: CGRectGetMidY(self.frame) + pipeOffset)
        gap.runAction(pipeSequence)
        
        if cheat3Active == true {
            
            gap.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipe1.size.width, self.frame.size.height + 100000))
            
        } else if cheat1Active == true {
            
            gap.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipe1.size.width, self.frame.height))
            
        } else {
        
            gap.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipe1.size.width / 2, gapHeight))
        }
        gap.physicsBody!.dynamic = false
        gap.physicsBody!.categoryBitMask = ColliderType.gap.rawValue
        gap.physicsBody!.collisionBitMask = ColliderType.gap.rawValue
        gap.physicsBody!.contactTestBitMask = ColliderType.bird.rawValue
        
        environment.addChild(gap)
    }
    
    func createBird() {
        
        let birdTexture = SKTexture(imageNamed: "flappy1.png")
        let birdTexture2 = SKTexture(imageNamed: "flappy2.png")
        
        bird = SKSpriteNode(texture: birdTexture)
        
        bird.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        
        let animation = SKAction.animateWithTextures([birdTexture, birdTexture2], timePerFrame: 0.3)
        let makeBirdFlap = SKAction.repeatActionForever(animation)
        bird.runAction(makeBirdFlap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture2.size().height/2)
        bird.physicsBody!.dynamic = true
        bird.physicsBody!.allowsRotation = false
        bird.physicsBody!.categoryBitMask = ColliderType.bird.rawValue
        bird.physicsBody!.collisionBitMask = ColliderType.object.rawValue
        bird.physicsBody!.contactTestBitMask = ColliderType.object.rawValue
        
        self.addChild(bird)

    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == ColliderType.gap.rawValue || contact.bodyB.categoryBitMask == ColliderType.gap.rawValue {
            
            score += 1
            scoreLabel.text = String(score)
        }
            
        else {
            
            if gameOver == false {
                
                gameOver = true
                
                self.speed = 0
                
                gameOverLabel.fontName = "Chalkboard"
                gameOverLabel.fontSize = 30
                gameOverLabel.text = "Game Over : Tap to play again"
                gameOverLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
                gameOverLabel.zPosition = 5
                self.addChild(gameOverLabel)
            }
        }
    }
    
    func musicBegan() {
        /* Called when a note plays */
        
        if startGame == true {
            
            self.removeAllChildren()
            self.createEnvironment()
            
            startGame = false
            
        }
            
        else {
            
            if gameOver == false {
                
                bird.physicsBody!.velocity = CGVectorMake(0, 0)
                bird.physicsBody!.applyImpulse(CGVectorMake(0, 50))
            }
                
            else {
                
                score = 0
                scoreLabel.text = "0"
                
                bird.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
                bird.physicsBody!.velocity = CGVectorMake(0,0)
                
                environment.removeAllChildren()
                makeBG()
                
                if cheat2Active == true {
                    
                    self.removeChildrenInArray([bird])
                    createBird()
                }
                
                if cheat3Active == true {createSky()}
                self.speed = 1
                
                cheat1Active = false
                cheat3Active = false
                gameOver = false
                self.removeChildrenInArray([gameOverLabel])
                
            }
        }
    }
    
    func cheat1Began() {
        
         if cheat1Active == false {
            
            print("cheat 1 active")
            cheat1Active = true
        }
    }
    
    func cheat2Began() {
        
        print("cheat 2 active")
        self.removeChildrenInArray([bird])
    
        let birdTexture = SKTexture(imageNamed: "flappy1.png")
        let birdTexture2 = SKTexture(imageNamed: "flappy2.png")
        let rbTexture1 = SKTexture(imageNamed: "RainbowOrU.png")
        let rbTexture2 = SKTexture(imageNamed: "RainbowOrD.png")
        let rbTexture3 = SKTexture(imageNamed: "RainbowRdU.png")
        let rbTexture4 = SKTexture(imageNamed: "RainbowRdD.png")
        let rbTexture5 = SKTexture(imageNamed: "RainbowPkU.png")
        let rbTexture6 = SKTexture(imageNamed: "RainbowPkD.png")
        let rbTexture7 = SKTexture(imageNamed: "RainbowPlU.png")
        let rbTexture8 = SKTexture(imageNamed: "RainbowPlD.png")
        let rbTexture9 = SKTexture(imageNamed: "RainbowBlU.png")
        let rbTexture10 = SKTexture(imageNamed: "RainbowBlD.png")
        let rbTexture11 = SKTexture(imageNamed: "RainbowAqU.png")
        let rbTexture12 = SKTexture(imageNamed: "RainbowAqD.png")
        let rbTexture13 = SKTexture(imageNamed: "RainbowGrU.png")
        let rbTexture14 = SKTexture(imageNamed: "RainbowGrD.png")
        
        bird = SKSpriteNode(texture: birdTexture)
    
        bird.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
    
        let animation = SKAction.animateWithTextures([birdTexture, birdTexture2, rbTexture1, rbTexture2, rbTexture3, rbTexture4, rbTexture5, rbTexture6, rbTexture7, rbTexture8, rbTexture9, rbTexture10, rbTexture11, rbTexture12, rbTexture13, rbTexture14], timePerFrame: 0.05)
        let makeBirdFlap = SKAction.repeatActionForever(animation)
        bird.runAction(makeBirdFlap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture2.size().height/2)
        bird.physicsBody!.dynamic = true
        bird.physicsBody!.allowsRotation = false
        bird.physicsBody!.categoryBitMask = ColliderType.bird.rawValue
        bird.physicsBody!.collisionBitMask = ColliderType.object.rawValue
        bird.physicsBody!.contactTestBitMask = ColliderType.object.rawValue
        
        cheat2Active = true
        self.addChild(bird)
    }
    
    func cheat3Began() {
        
        if cheat3Active == false {
        
            print("cheat 3 active")
            self.removeChildrenInArray([sky, gap])
            cheat3Active = true
        }
    }
    
    func cheat4Began() {
        
        print("cheat 4 active")
        self.score += 100
        scoreLabel.text = String(score)
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
