//
//  ParticipantView.swift
//  iOSMeetingSDKRefApp
//
//  Created by Ron DiNapoli on 6/30/21.
//

import UIKit
import MeetingSDK_iOS

class ParticipantView: UIView {
    var heightConstraint:NSLayoutConstraint!
    var widthConstraint:NSLayoutConstraint!
    private var videoView_:VideoView? = nil
    //private var lastUIImage:UIImage? = nil
    var title:UILabel? = nil
    var displayName:String? {
        get {
            return ""
        }
        set(newValue) {
            title?.text = newValue
        }
    }
    
    var streamId:String = ""
    var videoView:VideoView? {
        get {
            return videoView_
        }
        
        // Whenever we update the value of the embedded videoView, we'll remove any previous
        // VideoViews in this ParticipanView and then add the new one into the view hierarchy
        set(newValue) {
            if let videoView = newValue {
                // Check for existing VideoView and remove
                for view in self.subviews {
                    if view is VideoView {
                        view.removeFromSuperview()
                    }
                }
                
                self.addSubview(videoView)
                
                videoView.translatesAutoresizingMaskIntoConstraints = false
                
                // Update constraints
                NSLayoutConstraint(item: videoView as Any, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0).isActive = true
                NSLayoutConstraint(item: videoView as Any, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
                NSLayoutConstraint(item: videoView as Any, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 20).isActive = true
                NSLayoutConstraint(item: videoView as Any, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
                
                videoView_ = videoView
            }
        }
    }
    
    required override init(frame: CGRect) {
        super.init(frame:frame)
        print("init")
        
        let labelRect = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: 20.0)
        title = UILabel(frame:labelRect)
        if let title = title {
            title.backgroundColor = .blue
            title.textColor = .white
            title.text = "Test Name"
            self.addSubview(title)
            
            // Add constraints
            title.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: title as Any, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: title as Any, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: title as Any, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0).isActive = true
            title.heightAnchor.constraint(equalToConstant: 20).isActive = true

            
        }

        // Hide the view until we get the first image and can adjust the size accordingly
        self.isHidden = true
        
        // Set repeating timer to fire until first UIImage comes in.
        // When we detect a value UIImage in the VideoView, we'll adjust the rectangle to match
        // the size of the image being displayed
        let _ = Timer.scheduledTimer(withTimeInterval: 0.5,
                                          repeats: true) {
            timer in

            if self.videoView?.frameView?.image != nil {
                // There's a valid UIImage, adjust frame accordingly
                let scaledImageRect = self.videoView?.frameView?.scaledImageRect
                
                self.frame.size = CGSize(width:(scaledImageRect?.size.width)!,height:(scaledImageRect?.size.height)!+20)
                self.isHidden = false
                timer.invalidate()
            }
        }
        
        // Add a border
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
    }
}
