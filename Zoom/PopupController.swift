//
//  PopupController.swift
//  Zoom
//
//  Created by Horace Ho on 28/10/2022.
//

import UIKit

class PopupController: UIViewController {

    var history = History(books: [])
    var hasBook = false
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var loadButton: UIButton!
    @IBOutlet var bookTitle: UITextView!
    @IBOutlet var pageLabel: UILabel!
    @IBOutlet var prevButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var pageSlider: UISlider!

    override func viewWillAppear(_ animated: Bool) {
        print("PopupController::viewWillAppear")
        setupPopup()
        updatePage()
    }

    override func viewDidAppear(_ animated: Bool) {
        print("PopupController::viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("PopupController::viewWillDisappear")
        notifyPage()
    }

    override func viewDidDisappear(_ animated: Bool) {
        print("PopupController::viewDidDisappear")
    }

    @IBAction func sliderValueChanged(_ sender:UISlider!) {
        updatePage()
        notifyPage()
    }

    @IBAction func tapInsideLoadButton() {
        print("tapInsideLoadButton")
        if let book = history.book() {
            if let url = book.path, url.startAccessingSecurityScopedResource() {
                defer  {
                    url.stopAccessingSecurityScopedResource()
                }
                NotificationCenter.default.post(name: NSNotification.Name("LoadUrl"), object: nil, userInfo: [
                    "url": url
                ])
                dismiss(animated: true)
            }
        }
    }

    @IBAction func tapInsideBackButton() {
        dismiss(animated: true)
    }

    @IBAction func tapInsidePrevButton() {
        if (pageSlider.value >= 1.0) {
            pageSlider.value -= 1.0
            updatePage()
            notifyPage()
        }
    }

    @IBAction func tapInsideNextButton() {
        if (pageSlider.value < pageSlider.maximumValue) {
            pageSlider.value += 1.0
            updatePage()
            notifyPage()
        }
    }

    @IBAction func tapInsideMoreButton() {
        dismiss(animated: true)
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    func setupPopup() {
        history.load()
        if let book = history.book() {
            bookTitle.text = book.name
            pageSlider.minimumValue = 1.0
            pageSlider.maximumValue = Float(book.count)
            pageSlider.setValue(Float(book.index), animated: true)

            prevButton.alpha = 1.0
            nextButton.alpha = 1.0
            pageLabel.alpha = 1.0
            pageSlider.alpha = 1.0
        } else {
            prevButton.alpha = 0.0
            nextButton.alpha = 0.0
            pageLabel.alpha = 0.0
            pageSlider.alpha = 0.0
        }
    }

    func pageIndex() -> Int {
        return Int(round((pageSlider.value - pageSlider.minimumValue) / 1.0))
    }

    func updatePage() {
        pageLabel.text = String(pageIndex())
    }

    func notifyPage() {
        NotificationCenter.default.post(name: NSNotification.Name("TurnPage"), object: nil, userInfo: [
            "index": pageIndex()
        ])
    }
}
