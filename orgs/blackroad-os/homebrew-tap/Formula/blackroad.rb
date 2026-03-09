class Blackroad < Formula
  desc "BlackRoad OS CLI - Sovereign AI Operating System"
  homepage "https://blackroad.io"
  url "https://github.com/BlackRoad-OS/blackroad-cli/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "Proprietary"
  head "https://github.com/BlackRoad-OS/blackroad-cli.git", branch: "main"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "BlackRoad", shell_output("#{bin}/blackroad --version")
  end
end
