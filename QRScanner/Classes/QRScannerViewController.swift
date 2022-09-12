//
//  QRScannerViewController.swift
//  QRScanner
//
//  Created by 周斌 on 2018/11/29.
//
import UIKit
import Foundation
import AVFoundation

public protocol QRScannerDelegate:class {
    func qrScannerDidFail(scanner:QRScannerViewController, error:QRScannerError)
    func qrScannerDidSuccess(scanner:QRScannerViewController, result:String)
}

open class QRScannerViewController: UIViewController {
    lazy var title_lbl: UILabel = {
        let label = UILabel()
        label.text = "Scan Tam QR to Transfer"
        label.textColor = .white
        label.font = UIFont(name: "Inter-Bold", size: 16)
        label.textAlignment = .center
        return label
    }()
    
    lazy var subtitle_lbl: UILabel = {
        let label = UILabel()
        label.text = "Make sure that QR code in the frame and clearly visibile"
        label.textColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.65)
        label.font = UIFont(name: "Inter-Regular", size: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    lazy var cross_img_vc: UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_cross")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    lazy var back_btn: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(backClicked), for: .touchUpInside)
        return button
    }()
    
    lazy var top_left_img_vc: UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_scan_img")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 162.0/255.0, green: 255.0/255.0, blue: 0/255.0, alpha: 1.0)
        return imageView
    }()
    
    lazy var top_right_img_vc: UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_scan_img")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 162.0/255.0, green: 255.0/255.0, blue: 0/255.0, alpha: 1.0)
        return imageView
    }()
    
    lazy var bottom_left_img_vc: UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_scan_img")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 162.0/255.0, green: 255.0/255.0, blue: 0/255.0, alpha: 1.0)
        return imageView
    }()

    lazy var bottom_right_img_vc: UIImageView = {
       let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_scan_img")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 162.0/255.0, green: 255.0/255.0, blue: 0/255.0, alpha: 1.0)
        return imageView
    }()
    
    public weak var delegate: QRScannerDelegate?
    public let squareView = QRScannerSquareView()
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    let cameraPreview: UIView = UIView()
    let maskLayer = CAShapeLayer()
    let metaDataQueue = DispatchQueue(label: "metaDataQueue",qos: .userInteractive)
    let videoQueue = DispatchQueue(label: "videoQueue",qos: .background)
    lazy var resourcesBundle:Bundle? = {
        if let path = Bundle.main.path(forResource: "QRScanner", ofType: "framework", inDirectory: "Frameworks"),
           let framework = Bundle(path: path),
           let bundlePath = framework.path(forResource: "QRScanner", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath){
            return bundle
        }
        return nil
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
//        checkPermissions()
        setUpLayout()
        setUpLayers()
    }
    
    @objc public func openAlbum(){
        QRScannerPermissions.authorizePhotoWith { [weak self] in
            if $0{
                let picker = UIImagePickerController()
                picker.sourceType = UIImagePickerController.SourceType.photoLibrary
                picker.delegate = self
                self?.present(picker, animated: true, completion: nil)
            }else{
                self?.delegate?.qrScannerDidFail(scanner: self!, error: QRScannerError.photoPermissionDenied)
            }
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //squareView.startAnimation()
        for ly in self.maskLayer.sublayers ?? []{
            ly.removeFromSuperlayer()
        }
        checkPermissions()
    }
    
    func checkPermissions(){
        QRScannerPermissions.authorizeCameraWith {[weak self] in
            if $0{
                self?.captureSession?.startRunning()
            }else{
                self?.delegate?.qrScannerDidFail(scanner: self!, error: QRScannerError.photoPermissionDenied)
            }
        }
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraPreview.bounds
        maskLayer.frame = view.bounds
        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(roundedRect: squareView.frame, cornerRadius: 16))
        maskLayer.path = path.cgPath
    }
    
    func setUpLayout(){
        view.backgroundColor = UIColor.black
        view.addSubview(cameraPreview)
        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        cameraPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cameraPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cameraPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let length = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 68
        view.addSubview(squareView)
        squareView.translatesAutoresizingMaskIntoConstraints = false
        squareView.widthAnchor.constraint(equalToConstant: length).isActive = true
        squareView.heightAnchor.constraint(equalToConstant: length).isActive = true
        squareView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        squareView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
       /* view.addSubview(torchItem)
        torchItem.setImage(UIImage(named: "Torch-off", in: resourcesBundle, compatibleWith: nil), for: UIControl.State.normal)
        torchItem.setImage(UIImage(named: "Torch-on", in: resourcesBundle, compatibleWith: nil), for: UIControl.State.selected)
        torchItem.addTarget(self, action: #selector(toggleTorch), for: UIControl.Event.touchUpInside)
        torchItem.isHidden = true
        torchItem.translatesAutoresizingMaskIntoConstraints = false
        torchItem.topAnchor.constraint(equalTo: squareView.bottomAnchor, constant: 30).isActive = true
        torchItem.heightAnchor.constraint(equalToConstant: 30).isActive = true
        torchItem.widthAnchor.constraint(equalToConstant: 30).isActive = true
        torchItem.centerXAnchor.constraint(equalTo: squareView.centerXAnchor).isActive = true*/
        self.view.addSubview(subtitle_lbl)
        subtitle_lbl.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            subtitle_lbl.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -38).isActive = true
        } else {
            subtitle_lbl.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -38).isActive = true
        }
        subtitle_lbl.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18).isActive = true
        subtitle_lbl.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -18).isActive = true

        self.view.addSubview(title_lbl)
        title_lbl.translatesAutoresizingMaskIntoConstraints = false
        title_lbl.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor).isActive = true
        title_lbl.bottomAnchor.constraint(equalTo: self.subtitle_lbl.topAnchor, constant: -12).isActive = true
        self.view.addSubview(cross_img_vc)
        
        cross_img_vc.translatesAutoresizingMaskIntoConstraints = false
        cross_img_vc.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 18).isActive = true
        cross_img_vc.widthAnchor.constraint(equalToConstant: 20).isActive = true
        cross_img_vc.heightAnchor.constraint(equalToConstant: 20).isActive = true
        if #available(iOS 11.0, *) {
            cross_img_vc.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 22).isActive = true
        } else {
            cross_img_vc.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 22).isActive = true
        }
        
        self.view.addSubview(back_btn)
        back_btn.translatesAutoresizingMaskIntoConstraints = false
        back_btn.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        back_btn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        back_btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        if #available(iOS 11.0, *) {
            back_btn.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            back_btn.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        }
        
        [top_left_img_vc, top_right_img_vc, bottom_left_img_vc, bottom_right_img_vc].forEach{
            self.view.addSubview($0)
        }
        top_left_img_vc.translatesAutoresizingMaskIntoConstraints = false
        top_left_img_vc.leadingAnchor.constraint(equalTo: self.squareView.leadingAnchor, constant: -24).isActive = true
        top_left_img_vc.topAnchor.constraint(equalTo: self.squareView.topAnchor, constant: -24).isActive = true
        top_left_img_vc.widthAnchor.constraint(equalToConstant: 55).isActive = true
        top_left_img_vc.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        top_right_img_vc.translatesAutoresizingMaskIntoConstraints = false
        top_right_img_vc.trailingAnchor.constraint(equalTo: self.squareView.trailingAnchor, constant: 24).isActive = true
        top_right_img_vc.topAnchor.constraint(equalTo: self.squareView.topAnchor, constant: -24).isActive = true
        top_right_img_vc.widthAnchor.constraint(equalToConstant: 55).isActive = true
        top_right_img_vc.heightAnchor.constraint(equalToConstant: 55).isActive = true

        bottom_left_img_vc.translatesAutoresizingMaskIntoConstraints = false
        bottom_left_img_vc.leadingAnchor.constraint(equalTo: self.squareView.leadingAnchor, constant: -24).isActive = true
        bottom_left_img_vc.topAnchor.constraint(equalTo: self.squareView.bottomAnchor, constant: -24).isActive = true
        bottom_left_img_vc.widthAnchor.constraint(equalToConstant: 55).isActive = true
        bottom_left_img_vc.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        bottom_right_img_vc.translatesAutoresizingMaskIntoConstraints = false
        bottom_right_img_vc.trailingAnchor.constraint(equalTo: self.squareView.trailingAnchor, constant: 24).isActive = true
        bottom_right_img_vc.topAnchor.constraint(equalTo: self.squareView.bottomAnchor, constant: -24).isActive = true
        bottom_right_img_vc.widthAnchor.constraint(equalToConstant: 55).isActive = true
        bottom_right_img_vc.heightAnchor.constraint(equalToConstant: 55).isActive = true

        
    }
    
    @objc func toggleTorch(bt:UIButton){
        bt.isSelected = !bt.isSelected
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)else{return}
        try? device.lockForConfiguration()
        device.torchMode = bt.isSelected ? .on : .off
        device.unlockForConfiguration()
    }
    
    func setUpLayers(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        let viewLayer = cameraPreview.layer
        previewLayer?.cornerRadius = 16
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        viewLayer.addSublayer(previewLayer!)
        maskLayer.fillColor = UIColor(white: 0.0, alpha: 0.7).cgColor
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        view.layer.insertSublayer(maskLayer, above: previewLayer)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        self.view.bringSubviewToFront(self.title_lbl)
        self.view.bringSubviewToFront(self.subtitle_lbl)
        self.view.bringSubviewToFront(self.cross_img_vc)
        self.view.bringSubviewToFront(self.back_btn)
        self.view.bringSubviewToFront(squareView)
        self.view.bringSubviewToFront(top_left_img_vc)
        self.view.bringSubviewToFront(top_right_img_vc)
        self.view.bringSubviewToFront(bottom_left_img_vc)
        self.view.bringSubviewToFront(bottom_right_img_vc)


        top_left_img_vc.transform = CGAffineTransform(scaleX: -1, y: 1)
        bottom_left_img_vc.transform = CGAffineTransform(scaleX: -1, y: -1)
        bottom_right_img_vc.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    @objc func backClicked(){
        self.navigationController?.popViewController(animated: true)
    }
    
    func playAlertSound(){
        guard let soundPath = resourcesBundle?.path(forResource: "noticeMusic.caf", ofType: nil)  else { return }
        guard let soundUrl = NSURL(string: soundPath) else { return }
        
        var soundID:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    func drawRect(resultObj:AVMetadataMachineReadableCodeObject){
        #if !targetEnvironment(simulator)
        let path = UIBezierPath()
        for point in resultObj.corners{
            let index = resultObj.corners.firstIndex(of: point) ?? 0
            if index == 0 {
                path.move(to: point)
            }else if index == resultObj.corners.count - 1,let first = resultObj.corners.first{
                path.addLine(to: point)
                path.move(to: point)
                path.addLine(to: first)
                path.close()
            }else{
                path.addLine(to: point)
                path.move(to: point)
            }
            
        }
        
        for ly in self.maskLayer.sublayers ?? []{
            ly.removeFromSuperlayer()
        }
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.lineWidth = 3
        layer.strokeColor = UIColor.green.cgColor
        self.maskLayer.addSublayer(layer)
        self.maskLayer.setNeedsDisplay()
        #endif
    }
    
 /*   func pathForCornersRounded(rect:CGRect) ->UIBezierPath
       {
           let path = UIBezierPath()
           path.move(to: CGPoint(x: 0 , y: 0))
           path.addLine(to: CGPoint(x: rect.size.width - rightTopRadius , y: 0))
           path.addQuadCurve(to: CGPoint(x: rect.size.width , y: rightTopRadius), controlPoint: CGPoint(x: rect.size.width, y: 0))
           path.addLine(to: CGPoint(x: rect.size.width , y: rect.size.height - rightBottomRadius))
           path.addQuadCurve(to: CGPoint(x: rect.size.width - rightBottomRadius , y: rect.size.height), controlPoint: CGPoint(x: rect.size.width, y: rect.size.height))
           path.addLine(to: CGPoint(x: leftBottomRadius , y: rect.size.height))
           path.addQuadCurve(to: CGPoint(x: 0 , y: rect.size.height - leftBottomRadius), controlPoint: CGPoint(x: 0, y: rect.size.height))
           path.addLine(to: CGPoint(x: 0 , y: leftTopRadius))
           path.addQuadCurve(to: CGPoint(x: 0 + leftTopRadius , y: 0), controlPoint: CGPoint(x: 0, y: 0))
           path.close()
           
           return path
       }
    */
    func setupCameraSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSession.Preset.high
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)else{
            delegate?.qrScannerDidFail(scanner: self, error: QRScannerError.invalidDevice)
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession?.addInput(input)
        } catch {
            print(error)
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession!.canAddOutput(videoOutput) {
            captureSession?.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        }
        
        let metaOutput = AVCaptureMetadataOutput()
        if captureSession!.canAddOutput(metaOutput) {
            captureSession?.addOutput(metaOutput)
            metaOutput.metadataObjectTypes = metaOutput.availableMetadataObjectTypes
            metaOutput.setMetadataObjectsDelegate(self, queue: metaDataQueue)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil, using: {[weak self] (noti) in
            guard let sf = self else{
                return
            }
            metaOutput.rectOfInterest = sf.previewLayer!.metadataOutputRectConverted(fromLayerRect: sf.squareView.frame)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension QRScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        guard let metadata = metadataDict as? [AnyHashable: Any],
              let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? [AnyHashable: Any],
              let brightness = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? NSNumber,
              let device = AVCaptureDevice.default(for: AVMediaType.video),device.hasTorch else{
            return
        }
        DispatchQueue.main.async {[weak self] in
           /* if self?.torchItem.isSelected == true{
                self?.torchItem.isHidden = false
            }else{
                self?.torchItem.isHidden = brightness.floatValue > 0
            } */
        }
    }
}

extension QRScannerViewController:AVCaptureMetadataOutputObjectsDelegate{
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first,
              let resultObj = previewLayer?.transformedMetadataObject(for: obj) as? AVMetadataMachineReadableCodeObject,
              let result = resultObj.stringValue else{
            return
        }
        captureSession?.stopRunning()
        playAlertSound()
        DispatchQueue.main.async {[weak self] in
            guard let sf = self else{
                return
            }
            sf.drawRect(resultObj: resultObj)
            sf.squareView.stopAnimation()
            sf.delegate?.qrScannerDidSuccess(scanner: sf, result: result)
        }
    }
}

extension QRScannerViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
              let ciImage = CIImage(image: image),
              let detector:CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]) else{
            return
        }
        let features = detector.features(in:ciImage)
        if let feature = features.first as? CIQRCodeFeature,let result = feature.messageString{
            delegate?.qrScannerDidSuccess(scanner: self, result: result)
        }
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
