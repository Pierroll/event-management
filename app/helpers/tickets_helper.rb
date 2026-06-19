# frozen_string_literal: true

module TicketsHelper
  def qr_code_svg(qr_code_string, module_size: 4)
    qrcode = RQRCode::QRCode.new(qr_code_string)
    qrcode.as_svg(
      module_size: module_size,
      standalone: true,
      use_path: true
    ).html_safe
  end
end
