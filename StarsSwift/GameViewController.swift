//
//  GameViewController.swift
//  StarsSwift
//
//  Created by Newcastle on 19.03.17.
//  Copyright © 2017 Newcastle. All rights reserved.
//

//import GLKit
import OpenGLES
import UIKit
//import GVRCardboardView

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer {
    return UnsafeRawPointer(bitPattern: i)!
}

let UNIFORM_MODELVIEWPROJECTION_MATRIX = 0
let UNIFORM_NORMAL_MATRIX = 1
var uniforms = [GLint](repeating: 0, count: 2)







class GameViewController: UIViewController {
    
     
     var _cardboardView: GVRCardboardView?;
     var _starsRenderer: StarsRenderer;
     var _renderLoop: StarsRenderLoop?;

//    deinit { }
    
   
     
     required init?(coder aDecoder: NSCoder) {
          _starsRenderer = StarsRenderer()
          super.init(coder: aDecoder)
          
//          fatalError("init(coder:) has not been implemented")
     }
     
     

     override func loadView() {
          
          
          _cardboardView = GVRCardboardView(frame: CGRect.zero)
          _cardboardView?.delegate = _starsRenderer;
          _cardboardView?.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
          
          
          _cardboardView?.vrModeEnabled = true;
          
          // Use double-tap gesture to toggle between VR and magic window mode.
          let doubleTapGesture:UITapGestureRecognizer
               = UITapGestureRecognizer(target: self,
                                        action:#selector(didDoubleTapView)
          );
          
          doubleTapGesture.numberOfTapsRequired = 2;
          _cardboardView?.addGestureRecognizer(doubleTapGesture)
          
          self.view = _cardboardView;
     }
     
     
     
     override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated);
          _renderLoop = StarsRenderLoop.init(target: _cardboardView,
                                             action: #selector(_cardboardView?.render));
          _starsRenderer.renderLoop = _renderLoop;
     }
   
     
     
     func didDoubleTapView(_ :Any?) {
          _cardboardView?.vrModeEnabled = !(_cardboardView?.vrModeEnabled)!;
     }
     
     
     
     
     
     
     
}
