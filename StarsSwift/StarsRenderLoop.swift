//
//  StarsRenderLoop.swift
//  StarsSwift
//
//  Created by Newcastle on 19.03.17.
//  Copyright © 2017 Newcastle. All rights reserved.
//

import Foundation



let kRenderInBackgroundThread:Bool = true;


class StarsRenderLoop : NSObject {
     
     private var _renderThread:Thread?;
     private var _displayLink: CADisplayLink?;
     private var _paused: Bool = false;
//     var nextFrameTime: TimeInterval?
     
     override init() {
          
     }
     
//     
//     func nextFrameTime() ->TimeInterval {
//          return _displayLink!.timestamp + (_displayLink!.duration * Double(_displayLink!.frameInterval))
//     }
//     
     
     init(target: Any?,
           action: Selector?) {
          super.init();
          _displayLink = CADisplayLink(target: target!, selector: action!);
          
          if (kRenderInBackgroundThread) {
               _renderThread = Thread.init(target: self,
                                           selector: #selector(threadMain),
                                           object: nil);
               
               _renderThread?.start()
          } else {
               _displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
          }
    
          NotificationCenter.default.addObserver(
               self,
               selector: #selector(self.applicationWillResignActive),
               name: NSNotification.Name(rawValue: "applicationWillResignActiveNotification"),
               object: nil)
          
          NotificationCenter.default.addObserver(
               self,
               selector: #selector(self.applicationDidBecomeActive),
               name: NSNotification.Name(rawValue: "applicationDidBecomeActiveNotification"),
               object: nil)
          
          
     
     
//          return self;

     }
     
     deinit {
          NotificationCenter.default.removeObserver(self);
     }
     
     
     
     
     
     func invalidate() {
          if (kRenderInBackgroundThread) {
               self.perform(#selector(self.renderThreadStop),
                            on: _renderThread!,
                            with: nil,
                   waitUntilDone: false);
          
          } else {
               _displayLink?.invalidate();
               _displayLink = nil;
          }
     }
     
     func paused()->Bool {
          return _paused;
     }
     
     func setPaused(_ paused: Bool) {
          _paused = paused;
          _displayLink!.isPaused = paused;
     }
     
     func nextFrameTime()-> TimeInterval {
          return _displayLink!.timestamp + (_displayLink!.duration
                                             * Double( _displayLink!.preferredFramesPerSecond));
     }

     
     
     
     
     
     
     
     
//     #pragma mark - Background thread rendering.
     
     
     func threadMain() {
          _displayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
     
          CFRunLoopRun();
     }

     
     
     func threadPause() {
          _displayLink?.isPaused = true;
     }
     
     func renderThreadStop() {
          _displayLink?.invalidate();
          _displayLink = nil;
          
          CFRunLoopStop(CFRunLoopGetCurrent());
     
          DispatchQueue.main.async {
               self._renderThread?.cancel();
               self._renderThread = nil;
          };
     }


     
     
     
     
     
//     #pragma mark - NSNotificationCenter
     
     @objc func applicationWillResignActive(_ notification :NSNotification) {
          if (kRenderInBackgroundThread) {
               self.perform(#selector(self.threadPause),
                            on: _renderThread!,
                            with: nil,
                            waitUntilDone: true)

          }
          else {
               self.threadPause();
          }
     }
     
     
     @objc func applicationDidBecomeActive(_ notification :NSNotification) {
          _displayLink?.isPaused = _paused;
     }
    


}
