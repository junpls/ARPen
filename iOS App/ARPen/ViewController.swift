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

struct RemoteSettings: Codable {
    let task: String
    let uid: Int
    let recording: Bool
}

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
        let scene = PenScene()
        scene.markerBox = MarkerBox()
        self.arSceneView.pointOfView?.addChildNode(scene.markerBox)
        
        buttonMap[.Button1] = button1
        buttonMap[.Button2] = button2
        buttonMap[.Button3] = button3

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
        
        // Track image target
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionImages = referenceImages
        }
        
        // Run the view's session
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // fetchRemoteSettings(repeatAfter: 1)
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
        
        // (Re-)activate currently active plugin
        if let currentActivePlugin = self.pluginManager.activePlugin, let currentScene = self.pluginManager.arManager.scene {
            currentActivePlugin.activatePlugin(withScene: currentScene, andView: self.arSceneView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        //arSceneView.session.pause()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    /*
    var fetchSettingsUrlSession: URLSession?
    let fetchSettingsUrl: String = "https://my.url/with/settings.json"
    var previousSettings: String?
    func fetchRemoteSettings(repeatAfter timeout:Int? = nil) {
        if fetchSettingsUrlSession == nil {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            fetchSettingsUrlSession = URLSession.init(configuration: config)
        }
        
        if let url = URL(string: fetchSettingsUrl) {
            fetchSettingsUrlSession?.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let res = try JSONDecoder().decode(RemoteSettings.self, from: data)
                        self.userStudyRecordManager.currentActiveUserID = res.uid
                        self.userStudyRecordManager.isRecording = res.recording
                        self.userStudyStateManager.task = res.task

                        // Refresh scene if something changed
                        if let jsonString = String(data: data, encoding: .utf8) {
                            if let prev = self.previousSettings, prev != jsonString {
                                DispatchQueue.main.async {
                                    self.resetScene()
                                }
                            }
                            self.previousSettings = jsonString
                        }
                    } catch let error {
                        print(error)
                    }
                }
                
                if let t = timeout {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(t), execute: {
                        self.fetchRemoteSettings(repeatAfter: t)
                    })
                }
            }.resume()
        }
    }
    */
    
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
    
    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        
        self.arSceneView.session.setWorldOrigin(relativeTransform: anchor.transform)
        
        // Create a plane to visualize the initial position of the detected image.
        let plane = SCNPlane(width: referenceImage.physicalSize.width,
                             height: referenceImage.physicalSize.height)
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, but
         `ARImageAnchor` assumes the image is horizontal in its local space, so
         rotate the plane to match.
         */
        planeNode.eulerAngles.x = -.pi / 2
        
        /*
         Image anchors are not tracked after initial detection, so create an
         animation that limits the duration for which the plane visualization appears.
         */
        planeNode.runAction(self.imageHighlightAction)
        
        // Add the plane visualization to the scene.
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARImageAnchor {
            self.arSceneView.session.setWorldOrigin(relativeTransform: anchor.transform)
        }
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }
    
    func resetScene() {
        if let scene = self.arSceneView.scene as? PenScene {
            scene.drawingNode.enumerateChildNodes {(node, pointer) in
                node.removeFromParentNode()
            }
        }
        self.activatePlugin(withID: self.currentActivePluginID)
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        self.resetScene()
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

}
