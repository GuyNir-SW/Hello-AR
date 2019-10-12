//
//  ViewController.swift
//  Hello-AR
//
//  Created by Guy Nir on 08/10/2019.
//  Copyright © 2019 Guy Nir. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var add2Button: UIButton!
    @IBOutlet weak var resetViewButton: UIButton!
    
    @IBOutlet weak var DrawButton: UIButton!
    private let label : UILabel = UILabel()
    
    
    let configuration = ARWorldTrackingConfiguration()
    
    var addedcubes : Int = 0
    
    
    
    //---------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.bringSubviewToFront(addButton)
        view.bringSubviewToFront(add2Button)
        view.bringSubviewToFront(resetViewButton)
        view.bringSubviewToFront(DrawButton)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                       ARSCNDebugOptions.showWorldOrigin]
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Detect planes
        self.configuration.planeDetection = .horizontal
        
        // Run the scene
        sceneView.session.run(configuration)
        
        /* Not sure why
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        */
        
 
        // Let there be light
        self.sceneView.autoenablesDefaultLighting = true
        
        // delegate to self, to enable getting renderer events
        sceneView.delegate = self
        
        // Add Gesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //Mark: Start adding elements
        
        
        // Cube
        let box = SCNBox(width: 0.1, height: 0.2, length: 0.3, chamferRadius: 0.05)
        let material = SCNMaterial()
        
        material.diffuse.contents = UIColor.red
        box.materials = [material]
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3 (1, 0.05, -0.3)
        
        
        
        
        
        
        // Text
        let text = SCNText(string: "Maya & Noga", extrusionDepth: 1.0)
        text.firstMaterial?.diffuse.contents = UIColor.blue
        
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3 (0, 0.05, -0.5)
        textNode.scale = SCNVector3 (0.02, 0.02, 0.02)
        
        self.sceneView.scene.rootNode.addChildNode(textNode)
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        
        //MARK: Sphere - Earth
        let sphere = SCNSphere(radius: 0.2)
        sphere.firstMaterial?.diffuse.contents = UIImage(named: "earth.jpg")
        sphere.firstMaterial?.specular.contents = UIImage(named: "earth_specular_map")
        
        
        let sphereNpde = SCNNode(geometry: sphere)
        sphereNpde.position = SCNVector3 (-0.5, 0.05, -1.0)
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(Double(360).deg2Rad()), z: 0, duration: 10)
        let rotateForever = SCNAction.repeatForever(rotateAction)
        sphereNpde.runAction(rotateForever)
        
        self.sceneView.scene.rootNode.addChildNode(sphereNpde)
        
        print ("Guy Debug")
        
        
        
        // JellyFish
        let jellyFishScene = SCNScene(named: "art.scnassets/Jellyfish.scn")
        let jellyFishNode = jellyFishScene?.rootNode.childNode(withName: "JellyfishSG", recursively: false)
        jellyFishNode?.position = SCNVector3Make(0.5, -0.2, -0.5)
        jellyFishNode?.name = "jellyfish"
        self.sceneView.scene.rootNode.addChildNode(jellyFishNode!)
        
    }
    
    // Tap action
    @objc func tapped (recognizer : UIGestureRecognizer) {
        
        print ("Tap detected")
        // Get the scene
        let sceneView = recognizer.view as! SCNView
        
        // Get the location that a touch took place
        let touchLocation = recognizer.location(in: sceneView)
        
        let hitTouch = sceneView.hitTest(touchLocation)
        
        
        // Did we touch any item
        if hitTouch.isEmpty {
            print ("found nothing")
        }
        else {
        
            print ("found a node")
            
            
            
            
            let result = hitTouch.first!
            let geometry = result.node.geometry
            print (geometry)
            
            // For a surface - add jellyfish on top of it, all others - move them
            if (result.node.name == "surface") {
                print ("Surface node")
                let jellyFishScene = SCNScene(named: "art.scnassets/Jellyfish.scn")
                let jellyFishNode = jellyFishScene?.rootNode.childNode(withName: "JellyfishSG", recursively: false)
                jellyFishNode?.name = "jellyfish"
                
                // Get the surface location
                let transform = result.node.worldTransform
                
                
                jellyFishNode?.position = SCNVector3Make(transform.m31, transform.m32, transform.m33)
                
                
                // Add to root node, since surfaces gets updated all the time
                self.sceneView.scene.rootNode.addChildNode(jellyFishNode!)
                
            }
            else {
                animateNode(node: result.node)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    
    //MARK: detect Planes
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
   
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print ("New flat surface detected")
        
        let surfaceNode = createSurface(planeAnchor: planeAnchor)
        
        // Use the Node that was added by AR, when the plane was detected
        node.addChildNode(surfaceNode)
        
        // Name this node
        node.name = "surface"
        
    }
    
    // Detect more area of plane
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print ("Updating flat surface")
        
        // We need to remove the old surface and add a new one
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let surfaceNode = createSurface(planeAnchor: planeAnchor)
        
        // Use the Node that was added by AR, when the plane was detected
        node.addChildNode(surfaceNode)
        
        
        
    }
    
    // Understand that 2 surfaces are actually one
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print ("Removing duplicate surface")
        // We need to remove the old surface and add a new one
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    
    // Set our own surface
    func createSurface(planeAnchor pa: ARPlaneAnchor) -> SCNNode {
        let surfaceNode = SCNNode(geometry: SCNPlane(width: CGFloat(pa.extent.x), height: CGFloat(pa.extent.z)))
        surfaceNode.geometry?.firstMaterial?.isDoubleSided = true
        surfaceNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "wood")
        surfaceNode.position = SCNVector3Make(pa.center.x, pa.center.y, pa.center.z)
        surfaceNode.eulerAngles = SCNVector3(Double(90).deg2Rad(), 0, 0)
        surfaceNode.name = "surface"
        return surfaceNode
        
    }
    
    
    @IBAction func add(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        node.position = SCNVector3(0, 0, 0.15 * Double(self.addedcubes))
        node.eulerAngles = SCNVector3(0, 0, (10.0 * Double(self.addedcubes)).deg2Rad())
        self.sceneView.scene.rootNode.addChildNode(node)
        
        self.addedcubes += 1
        
    }
    
    @IBAction func resetView(_ sender: Any) {
        self.restartSession()
    }
    @IBAction func Add2(_ sender: Any) {
        
        // Get Current camera position
       
        // Add Sphere
        let node = SCNNode()
        node.geometry = SCNCapsule(capRadius: 0.1, height: 0.3)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        
        node.position = SCNVector3(0, 0, 0.15 * Double(self.addedcubes))
        self.sceneView.scene.rootNode.addChildNode(node)
        
        self.addedcubes += 1
        
    }
    
    
    func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            
            node.removeFromParentNode()
        }
        self.sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors ])
        
        addedcubes = 0
        
    }
    
    // Not sure we need this, we are using "isHighlighted" in WillRenderScene
    @IBAction func Draw(_ sender: Any) {
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        if (DrawButton.isHighlighted) {
            print ("location: \(location.x), \(location.y), \(location.z)" )
            print ("orientation: \(orientation.x), \(orientation.y), \(orientation.z)" )
            print ("Camera: \(currentPositionOfCamera.x), \(currentPositionOfCamera.y), \(currentPositionOfCamera.z)" )
            
            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.01))
            sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            sphereNode.position = currentPositionOfCamera
            self.sceneView.scene.rootNode.addChildNode(sphereNode)
        }
        
    }
    
    func animateNode(node: SCNNode) {
        // Make sure only 1 animation is taking place at a time
        if (node.animationKeys.isEmpty) {

            // Make sure we animate inside a transaction
            SCNTransaction.begin()
            
            // Set the animation
            let spin = CABasicAnimation(keyPath: "position")
            let currPos = node.presentation.position
            spin.fromValue = currPos
            spin.toValue = SCNVector3Make(currPos.x, currPos.y, currPos.z - 0.1)
            spin.autoreverses = true
            spin.duration = 0.5
            spin.repeatCount = 5
            node.addAnimation(spin, forKey: "position")
            
            // Set action at end of animation
            SCNTransaction.completionBlock = {
                if node.name == "jellyfish" {
                    node.removeFromParentNode()
                }
            }
            
            // End of transaction
            SCNTransaction.commit()
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}


extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}
