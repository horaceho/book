//
//  ViewController.swift
//  Book
//
//  Created by Horace Ho on 20/10/2022.
//

import UIKit
import PDFKit

class ViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView?
    var pdfDocument: PDFDocument?

    @IBOutlet var infoText: UITextView!
    @IBOutlet var bookButton: UIView!
    @IBOutlet var prevButton: UIView!
    @IBOutlet var nextButton: UIView!
    @IBOutlet var trashButton: UIView!

    @IBOutlet var configView: UIView! {
        didSet {
            configView.layer.cornerRadius = 8
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        //
    }

    override func viewWillDisappear(_ animated: Bool) {
        //
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
        
        infoText.text = "Hi"
    }

    @IBAction func tapInsideBookButton() {
        openBook()
    }
    
    @IBAction func tapInsidePrevButton() {
      // do something
    }

    @IBAction func tapInsideNextButton() {
      // do something
    }
    
    @IBAction func tapInsideTrashButton() {
      // do something
    }

    @IBAction func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        print(location)
    }

    @IBAction func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        guard let gestureView = gesture.view else {
            return
        }

        gestureView.center = CGPoint(
            x: gestureView.center.x + translation.x,
            y: gestureView.center.y + translation.y
        )

        gesture.setTranslation(.zero, in: view)
    }
    
    func openBook()
    {
        if let pdfUrl = Bundle.main.url(forResource: "WatchOS9", withExtension: "pdf") {
            let document = PDFDocument(url: pdfUrl)

            // Set our document to the view, center it, and set a background color
            pdfView?.document = document
            pdfView?.autoScales = true
//            pdfView?.backgroundColor = UIColor.lightGray
        }
    }
}
