//
//  DetailViewController.swift
//  AlecrimCoreDataExample
//
//  Created by Vanderlei Martinelli on 2014-11-30.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet var detailChildLabel: UILabel!
    @IBOutlet var detailChildrenLabel: UILabel!


    var detailItem: Event? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let label = self.detailDescriptionLabel, let event = self.detailItem {
            label.text = event.timeStamp.description
        }
        
        if let label = self.detailChildLabel, let child = self.detailItem?.child {
            detailChildLabel.text = child.title
        }
        
        if let label = self.detailChildrenLabel, let event = self.detailItem where event.children.count > 0 {
            var text = ""
            
            for child in event.children {
                text += child.title! + ", "
            }
            
            detailChildrenLabel.text = text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

