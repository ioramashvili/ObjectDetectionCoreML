import UIKit
import PhotosUI
import Vision
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet var previewView : UIView!
    @IBOutlet var preview: UIImageView!
    
    @IBOutlet var resent50Label: UILabel!
    @IBOutlet var googleNetPlacesLabel: UILabel!
    @IBOutlet var Inceptionv3Label: UILabel!
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    
    var timerCount: Int = 0
    
    var selectedImage: UIImage = UIImage() {
        didSet {
            timerCount = 1
            
            preview.image = selectedImage
            
//            detectForInceptionv3()
            detectForResent50()
            detectForGoogleNetPlaces()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resent50Label.text = ""
        googleNetPlacesLabel.text = ""
        Inceptionv3Label.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupAVCapture()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.timerCount -= 1
        }
    }
    
//    func detectForInceptionv3() {
//        let model = try! VNCoreMLModel(for: Inceptionv3().model)
//        let requset = VNCoreMLRequest(model: model) { (results, error) in
//            guard let results = results.results as? [VNClassificationObservation], let first = results.first else {
//                fatalError("detectForInceptionv3 failed")
//            }
//            
//            self.Inceptionv3Label.text = "Inceptionv3: \(first.identifier) \(first.confidence)"
//        }
//        
//        let handler = VNImageRequestHandler(cgImage: selectedImage.cgImage!, options: [:])
//        try? handler.perform([requset])
//    }
    
    func detectForGoogleNetPlaces() {
        let model = try! VNCoreMLModel(for: GoogLeNetPlaces().model)
        let requset = VNCoreMLRequest(model: model) { (results, error) in
            guard let results = results.results as? [VNClassificationObservation], let first = results.first else {
                fatalError("detectForGoogleNetPlaces failed")
            }
            
            self.googleNetPlacesLabel.text = "GoogLeNetPlaces: \(first.identifier) \(first.confidence)"
        }
        
        let handler = VNImageRequestHandler(cgImage: selectedImage.cgImage!, options: [:])
        try? handler.perform([requset])
    }
    
    func detectForResent50() {
        let model = try! VNCoreMLModel(for: Resnet50().model)
        let requset = VNCoreMLRequest(model: model) { (results, error) in
            guard let results = results.results as? [VNClassificationObservation], let first = results.first else {
                fatalError("detectForResent50 failed")
            }
            
            self.resent50Label.text = "Resnet50: \(first.identifier) \(first.confidence)"
        }
        
        let handler = VNImageRequestHandler(cgImage: selectedImage.cgImage!, options: [:])
        try? handler.perform([requset])
    }
}


extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
    func setupAVCapture(){
        session.sessionPreset = .hd1280x720
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }
        
        captureDevice = device
        beginSession()
    }
    
    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            err = error
            deviceInput = nil
        }
        if err != nil {
            print("error: \(err?.localizedDescription)")
        }
        if self.session.canAddInput(deviceInput!){
            self.session.addInput(deviceInput!);
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames=true
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
        
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = .resizeAspectFill
        
        let rootLayer = self.previewView.layer
        rootLayer.masksToBounds = true
        self.previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(self.previewLayer)
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if timerCount <= 0 {
            let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            DispatchQueue.main.async {
                self.selectedImage = image!
            }
        }
    }
    
    func stopCamera(){
        session.stopRunning()
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: 1, orientation: .right)
    }
}
