import UIKit

private final class PosterPreviewStyler {
    var separatorColor: UIColor {
        return UIColor.App.separator
    }

    var progressContentViewColor: UIColor {
        return UIColor(white: 1, alpha: 0.4)
    }

    var progressIndicatorViewColor: UIColor {
        return UIColor.App.kp
    }
    
    lazy var serialFormatter = AppServicesFactory.shared.makeTextSerialFormatter()

    func attributed(posterNotReleasedDate day: String?, month: String?) -> NSAttributedString? {
        guard let day = day, let month = month else { return nil }
        let dayAttr = NSAttributedString(string: day,
                                         attributes: NSAttributedString.basicAttributes(36, .bold,
                                                                                        alignment: .center,
                                                                                        color: UIColor(white: 1, alpha: 0.9),
                                                                                        lineHeight: 44))

        let monthAttr = NSAttributedString(string: "\n\(month)",
            attributes: NSAttributedString.basicAttributes(13, .semibold,
                                                           alignment: .center,
                                                           color: UIColor(white: 1, alpha: 0.9),
                                                           lineHeight: 14))

        let mas = NSMutableAttributedString()
        mas.append(dayAttr)
        mas.append(monthAttr)

        return NSAttributedString(attributedString: mas)
    }

    func attributed(posterPlaceholder string: String?) -> NSAttributedString? {
        guard let string = string else { return nil }
        let color = UIColor(white: 1, alpha: 0.5)
        let attributes = NSAttributedString.basicAttributes(36, .light, alignment: .center, color: color)
        return NSAttributedString(string: string, attributes: attributes)
    }

    func attributed(time string: String?) -> NSAttributedString? {
        guard let string = string else { return nil }
        let attributes = NSAttributedString.basicAttributes(11, .semibold, alignment: .right, color: .white)
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    
    func attributed(seriesCount: Int) -> NSAttributedString? {
        let string = serialFormatter.format(seasons: 0, series: seriesCount)
        let attributes = NSAttributedString.basicAttributes(11, .semibold, alignment: .right, color: .white)
        return NSAttributedString(string: string, attributes: attributes)
    }

    func makeDefaultGradientParameters() -> GradientParameters {
        return GradientParameters(colors: [UIColor.color(gray: 20, a: 0), UIColor.color(gray: 20, a: 0.2), UIColor.color(gray: 20, a: 0.71)],
                                  locations: [0, 0.48, 1],
                                  direction: GradientDirection(start: CGPoint(x: 0.5, y: 0),
                                                               end: CGPoint(x: 0.5, y: 1)))
    }

    func makeNotReleasedGradientParameters() -> GradientParameters {
        return GradientParameters(colors: [UIColor(white: 0, alpha: 0.7), UIColor(white: 0, alpha: 0.7)],
                                  locations: [0, 1],
                                  direction: GradientDirection(start: CGPoint(x: 0, y: 0),
                                                               end: CGPoint(x: 1, y: 1)))
    }

}

final class PosterPreview: NibView {
    @IBOutlet private weak var posterImageView: GradientImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var groupIconImageView: UIImageView!
    @IBOutlet private weak var posterLabel: UILabel!
    @IBOutlet private weak var playImageView: UIImageView!
    @IBOutlet private weak var progressContentView: OpaqueView! {
        didSet {
            progressContentView.backgroundColor = styler.progressContentViewColor
        }
    }
    @IBOutlet private weak var progressIndicatorView: OpaqueView! {
        didSet {
            progressIndicatorView.backgroundColor = styler.progressIndicatorViewColor
        }
    }
    @IBOutlet private weak var progressHeight: NSLayoutConstraint!
    @IBOutlet private weak var progressIndicatorWidth: NSLayoutConstraint!

    private let styler = PosterPreviewStyler()
    private var progressValue: Float = 0
    
    func setup(asset: AssetInfoViewModel) {
        setupAssetPoster(asset: asset)
        posterLabel.isHidden = true
        if asset.isGroup {
            groupIconImageView.isHidden = false
            playImageView.isHidden = true
            textLabel.attributedText = styler.attributed(seriesCount: asset.episodes.count)
            progress(0)
        } else {
            groupIconImageView.isHidden = true
            playImageView.isHidden = false
            textLabel.attributedText = styler.attributed(time: asset.duration ?? "")
            progress(asset.progress)
        }
    }
    
    private func setupAssetPoster(asset: AssetInfoViewModel) {
        posterLabel.isHidden = true
        posterImageView.removeGradient()
        
        if let imagePath = asset.storedPosterURI?.path, let image = UIImage(contentsOfFile: imagePath) {
            posterImageView.image = image
        } else if let url = asset.posterURL ?? asset.episodes.first?.posterURL {
            setupPoster(at: url)
        } else {
            posterImageView.image = UIImage.Generated.emptyPoster
        }
    }
    
    private func setupPoster(at url: URL, applyGradient: Bool = true) {
        posterImageView.sd_setImage(with: url, placeholderImage: UIImage.Generated.placeholder) { [weak self] img, _, _, _ in
            if img != nil {
                self?.applyGradient(released: applyGradient)
            }
        }
    }
    
    private func applyGradient(released: Bool) {
        if released {
            posterImageView.applyGradient(styler.makeDefaultGradientParameters())
        } else {
            posterImageView.applyGradient(styler.makeNotReleasedGradientParameters())
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if progressContentView.isHidden == false {
            updateProgressIndicatorWidth(progressValue)
        }
    }
}

extension PosterPreview {
    func progress(_ value: Float) {
        progressValue = value

        if value > 0 && value < 1 {
            progressContentView.isHidden = false
            progressHeight.constant = 4
            updateProgressIndicatorWidth(value)
        } else {
            progressContentView.isHidden = true
            progressHeight.constant = 0
        }
    }

    private func updateProgressIndicatorWidth(_ value: Float) {
        progressIndicatorWidth.constant = progressContentView.width * CGFloat(value)
    }
}
