//
//  ParticipantsTableViewCell.swift
//  iOSMeetingSDKRefApp
//
//  Created by Aaron Treinish on 5/12/21.
//

import UIKit

class ParticipantsTableViewCell: UITableViewCell {

    @IBOutlet weak var userUUIDLabel: UILabel!
    @IBOutlet weak var audioInfoStreamIdLabel: UILabel!
    @IBOutlet weak var audioInfoSiteLabel: UILabel!
    @IBOutlet weak var seeVideoInfoButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
