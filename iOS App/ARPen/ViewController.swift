//
//  ViewController.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

/**
 The "Main" ViewController. This ViewController holds the instance of the PluginManager.
 Furthermore it holds the ARKitView.
 */
class ViewController: UIViewController, ARSCNViewDelegate, PluginManagerDelegate {

    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var arPenLabel: UILabel!
    @IBOutlet weak var arPenActivity: UIActivityIndicatorView!
    @IBOutlet weak var arPenImage: UIImageView!
    @IBOutlet weak var arKitLabel: UILabel!
    @IBOutlet weak var arKitActivity: UIActivityIndicatorView!
    @IBOutlet weak var arKitImage: UIImageView!
    @IBOutlet var arSceneView: ARSCNView!
    @IBOutlet weak var pluginMenuScrollView: UIScrollView!
    @IBOutlet weak var undoButton: UIButton!
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    
    var buttonMap: [Button:UIButton] = [Button:UIButton]()

    let menuButtonHeight = 70
    let menuButtonPadding = 5
    var currentActivePluginID = 1
    /**
     The PluginManager instance
     */
    var pluginManager: PluginManager!
    
    /// Manager for user study data
    let userStudyRecordManager = UserStudyRecordManager()
    /// Manager for user study state
    let userStudyStateManager = UserStudyStateManager()
    
    var s:ARPGeomNode?
    var p:ARPGeomNode?
    
    /**
     A quite standard viewDidLoad
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a new scene
        let scene = PenScene(named: "art.scnassets/ship.scn")!
        scene.markerBox = MarkerBox()
        self.arSceneView.pointOfView?.addChildNode(scene.markerBox)
        
        buttonMap[.Button1] = button1
        buttonMap[.Button2] = button2
        buttonMap[.Button3] = button3

        //button1.setTitle("Bla?", for: .normal)
        /*
        if let cube = try? ARPBox(width: 0.1, height: 0.1, length: 0.1) {
            scene.rootNode.addChildNode(cube)
            cube.position.x = -0.2
            cube.scale = SCNVector3(1,1,1)
            cube.applyTransform()
            try? cube.rebuild()
            //cube.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 1)))
            //cube.applyTransform()
        }
        
        if let sphere1 = try? ARPSphere(radius: 0.05), let box = try? ARPBox(width: 0.1, height: 0.2, length: 0.1) {
            scene.rootNode.addChildNode(sphere1)
            scene.rootNode.addChildNode(box)
            
            box.position.y = 0.05
            box.scale = SCNVector3(0.5, 0.5, 0.5)
            box.rotation = SCNVector4(0,0,1,Double.pi/4)
            
            box.position.y -= 0.05
            sphere1.position.y -= 0.05

            box.applyTransform()
            sphere1.applyTransform()
            box.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 1)))
            //sphere2.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 1)))

            if let bool = try? ARPBoolNode(a: sphere1, b: box, operation: BooleanOperation.cut) {
                scene.rootNode.addChildNode(bool)
                bool.position.y = -0.1;
                bool.scale = SCNVector3(2, 2, 2)
                bool.rotation = SCNVector4(0,0,1,Double.pi/2)
                bool.applyTransform()
                //bool.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 1)))
                try? bool.rebuild()
                s = box
            } else {
                print("lol, error")
            }
            
        }
        
        var ppoints = [SCNVector3]()
        ppoints.append(SCNVector3(-0.03, 0, -0.03))
        ppoints.append(SCNVector3(0.03, 0, -0.03))
        ppoints.append(SCNVector3(0.03, 0, 0.03))
        ppoints.append(SCNVector3(-0.03, 0, 0.03))
        
        var profile = ARPPath(points: ppoints, closed: true)
        profile.position = SCNVector3(0.2, 0, 0)
        profile.applyTransform()
        
        var epoints = [SCNVector3]()
        epoints.append(SCNVector3(-0.03, 0, -0.03))
        epoints.append(SCNVector3(-0.5, 0.5, -0.5))
        
        var extrusion = ARPPath(points: epoints, closed: false)
        extrusion.position = SCNVector3(0.2, 0, 0)
        extrusion.applyTransform()
        
        if let pipe = try? ARPSweep(profile: profile, path: extrusion) {
            scene.rootNode.addChildNode(pipe)
            pipe.position.x -= 0.1
            //pipe.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))
            //profile.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 1, duration: 1)))
            p = profile
            //try? extrusion.rebuild()
        }
        
        var ppoints2 = [SCNVector3]()
        ppoints2.append(SCNVector3(-0.03, 0, -0.03))
        ppoints2.append(SCNVector3(0.03, 0, -0.03))
        ppoints2.append(SCNVector3(0.03, 0, 0.03))
        ppoints2.append(SCNVector3(-0.03, 0, 0.03))
        
        var path = ARPPath(points: ppoints2, closed: true)
        path.position = SCNVector3(0,0,-0.2)
        scene.rootNode.addChildNode(path)
        */
        /*
        let smallBox = ARPBox(width: 0.1, height: 0.1, length: 0.1)
        scene.drawingNode.addChildNode(smallBox)
        
        let smallBox2 = ARPBox(width: 0.1, height: 0.1, length: 0.1)
        smallBox2.position.x = 0.05
        smallBox2.position.z = 0.05
        smallBox2.position.y = 0.05
        smallBox2.applyTransform()
        scene.drawingNode.addChildNode(smallBox2)
        
        if let bool = try? ARPBoolNode(a: smallBox, b: smallBox2, operation: .cut) {
            scene.drawingNode.addChildNode(bool)
        }
         */
        arSceneView.delegate = self

        self.pluginManager = PluginManager(scene: scene)
        self.pluginManager.delegate = self
        self.arSceneView.session.delegate = self.pluginManager.arManager
        
        self.arSceneView.autoenablesDefaultLighting = true
        self.arSceneView.pointOfView?.name = "iDevice Camera"
        
        // Set the scene to the view
        arSceneView.scene = scene
        
        setupPluginMenu()
        activatePlugin(withID: currentActivePluginID)
        
        // set user study record manager reference in the app delegate (for saving state when leaving the app)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.userStudyRecordManager = self.userStudyRecordManager
        } else {
            print("Record manager was not set up in App Delegate")
        }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        arSceneView.session.run(configuration)
    }
    
    /**
     viewWillAppear. Init the ARSession
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        //let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        //arSceneView.session.run(configuration)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        //arSceneView.session.pause()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupPluginMenu(){
        //define target height and width for the scrollview to hold all buttons
        let targetWidth = Int(self.pluginMenuScrollView.frame.width)
        let targetHeight = self.pluginManager.plugins.count * (menuButtonHeight+2*menuButtonPadding)
        self.pluginMenuScrollView.contentSize = CGSize(width: targetWidth, height: targetHeight)
        
        //iterate over plugin array from plugin manager and create a button for each in the scrollview
        for (index,plugin) in self.pluginManager.plugins.enumerated() {
            //calculate position inside the scrollview for current button
            let frameForCurrentButton = CGRect(x: 0, y: index*(menuButtonHeight+2*menuButtonPadding), width: targetWidth, height: menuButtonHeight+2*menuButtonPadding)
            let buttonForCurrentPlugin = UIButton(frame: frameForCurrentButton)
            
            //define properties of the button: tag for identification & action when pressed
            buttonForCurrentPlugin.tag = index + 1 //+1 needed since finding a view with tag 0 does not work
            buttonForCurrentPlugin.addTarget(self, action: #selector(pluginButtonPressed), for: .touchUpInside)
            
            buttonForCurrentPlugin.backgroundColor = UIColor.clear
            buttonForCurrentPlugin.setImage(plugin.pluginImage, for: .normal)
            buttonForCurrentPlugin.imageEdgeInsets = UIEdgeInsets(top: CGFloat(menuButtonPadding), left: CGFloat(menuButtonPadding), bottom: CGFloat(menuButtonPadding+menuButtonHeight/3), right: CGFloat(menuButtonPadding))
            buttonForCurrentPlugin.imageView?.contentMode = .scaleAspectFit
            
            var titleLabelFrame : CGRect
            if let _ = buttonForCurrentPlugin.imageView?.frame {
                titleLabelFrame = CGRect(x: CGFloat(menuButtonPadding) , y: CGFloat(menuButtonPadding+menuButtonHeight*2/3), width: CGFloat(targetWidth - 2*menuButtonPadding), height: CGFloat(menuButtonHeight/3))
            } else {
                titleLabelFrame = CGRect(x: CGFloat(menuButtonPadding) , y: CGFloat(menuButtonPadding), width: CGFloat(targetWidth - 2*menuButtonPadding), height: CGFloat(menuButtonHeight))
            }
            
            let titleLabel = UILabel(frame: titleLabelFrame)
            titleLabel.text = plugin.pluginIdentifier
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.textAlignment = .center
            titleLabel.baselineAdjustment = .alignCenters
            buttonForCurrentPlugin.addSubview(titleLabel)
            
            self.pluginMenuScrollView.addSubview(buttonForCurrentPlugin)
        }
    }
    
    @objc func pluginButtonPressed(sender: UIButton!){
        activatePlugin(withID: sender.tag)
    }
    
    func activatePlugin(withID pluginID:Int) {
        //deactivate highlighting of the button from the currently active plugin
        if let currentActivePluginButton = self.pluginMenuScrollView.viewWithTag(currentActivePluginID) as? UIButton {
            currentActivePluginButton.backgroundColor = UIColor.clear
        }
        
        //find the button for the new active plugin and set the highlighted color
        guard let newActivePluginButton = self.pluginMenuScrollView.viewWithTag(pluginID) as? UIButton else {
            print("Button for new plugin not found")
            return
        }
        newActivePluginButton.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        
        if let currentActivePlugin = self.pluginManager.activePlugin {
            currentActivePlugin.deactivatePlugin()
        }
        //activate plugin in plugin manager and update currently active plugin property
        let newActivePlugin = self.pluginManager.plugins[pluginID-1] //-1 needed since the tag is one larger than index of plugin in the array (to avoid tag 0)
        self.pluginManager.activePlugin = newActivePlugin
        //if the new plugin conforms to the user study record plugin protocol, then pass a reference to the record manager (allowing to save data to it)
        if var pluginConformingToUserStudyProtocol = newActivePlugin as? UserStudyRecordPluginProtocol {
            pluginConformingToUserStudyProtocol.recordManager = self.userStudyRecordManager
        }
        if var pluginConformingToUserStudyProtocol = newActivePlugin as? UserStudyStatePluginProtocol {
            pluginConformingToUserStudyProtocol.stateManager = self.userStudyStateManager
        }
        if var pluginConformingToUIButtonProtocol = newActivePlugin as? UIButtonPlugin {
            pluginConformingToUIButtonProtocol.penButtons = self.buttonMap
            pluginConformingToUIButtonProtocol.undoButton = self.undoButton
        }
        if let currentScene = self.pluginManager.arManager.scene {
            newActivePlugin.activatePlugin(withScene: currentScene, andView: self.arSceneView)
        }
        currentActivePluginID = pluginID
    }
    
    /**
     Prepare the SettingsViewController by passing the scene
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else { return }
        
        if segueIdentifier == "ShowSettingsSegue" {
            let destinationVC = segue.destination as! UINavigationController
            guard let destinationSettingsController = destinationVC.viewControllers.first as? SettingsTableViewController else {
                return
                
            }
            destinationSettingsController.scene = self.arSceneView.scene as! PenScene
            //pass reference to the record manager (to show active user ID and export data)
            destinationSettingsController.userStudyRecordManager = self.userStudyRecordManager
            destinationSettingsController.userStudyStateManager = self.userStudyStateManager
        }
        
    }
    
    
    // Mark: - ARManager Delegate
    /**
     Callback from the ARManager
     */
    func arKitInitialiazed() {
        guard let arKitActivity = self.arKitActivity else {
            return
        }
        arKitActivity.isHidden = true
        self.arKitImage.isHidden = false
        checkVisualEffectView()
    }
    
    // Mark: - PenManager delegate
    /**
     Callback from PenManager
     */
    func penConnected() {
        guard let arPenActivity = self.arPenActivity else {
            return
        }
        arPenActivity.isHidden = true
        self.arPenImage.isHidden = false
        checkVisualEffectView()
    }
    
    func penFailed() {
        guard let arPenActivity = self.arPenActivity else {
            return
        }
        arPenActivity.isHidden = true
        self.arPenImage.image = UIImage(named: "Cross")
        self.arPenImage.isHidden = false
        checkVisualEffectView()
    }
    
    /**
     This method will be called after `penConnected` and `arKitInitialized` to may hide the blurry overlay
     */
    func checkVisualEffectView() {
        if self.arPenActivity.isHidden && self.arKitActivity.isHidden {
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1), execute: {
//                UIView.animate(withDuration: 0.5, animations: {
//                    self.visualEffectView.alpha = 0.0
//                }, completion: { (completion) in
//                    self.visualEffectView.removeFromSuperview()
//                })
//            })
            self.visualEffectView.removeFromSuperview()
        }
    }
    
    //Software Pen Button Actions
    @IBAction func softwarePenButtonPressed(_ sender: Any) {
        self.pluginManager.button(.Button1, pressed: true)
    }
    @IBAction func softwarePenButtonReleased(_ sender: Any) {
        self.pluginManager.button(.Button1, pressed: false)
    }
    @IBAction func softwarePenButton2Pressed(_ sender: Any) {
        self.pluginManager.button(.Button2, pressed: true)
    }
    @IBAction func softwarePenButton2Released(_ sender: Any) {
        self.pluginManager.button(.Button2, pressed: false)
    }
    @IBAction func softwarePenButton3Pressed(_ sender: Any) {
        self.pluginManager.button(.Button3, pressed: true)
    }
    @IBAction func softwarePenButton3Released(_ sender: Any) {
        self.pluginManager.button(.Button3, pressed: false)
    }
    
    var count:Int = 0
    var busy = false
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        return
        if !busy {
            busy = true
            DispatchQueue.global(qos: .userInitiated).async {
/*
                self.s?.rotation = SCNVector4(0, 0, 1, time/3)*/
                self.s?.applyTransform()
//                self.busy = false
 
                
//                self.p?.points[1].position.y = Float(abs(sin(time/3)))*0.1 + 0.01
//                self.p?.points[1].position.x = Float(abs(sin(time/3)))*0.1 + 0.01
                //try? self.p?.applyTransform()
                //try? self.p?.rebuild()
                self.busy = false
 
            }
        }

    }
}
