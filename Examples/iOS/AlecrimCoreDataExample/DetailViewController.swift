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
        if let event = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = event.timeStamp.description
            }
            
            if let label = self.detailChildLabel, let child = event.child {
                detailChildLabel.text = child.title
            }
            
            if let label = self.detailChildrenLabel where event.children.count > 0 {
                detailChildrenLabel.text = (map(event.children, { $0.title! }) as NSArray).componentsJoinedByString(", ")
            }
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

