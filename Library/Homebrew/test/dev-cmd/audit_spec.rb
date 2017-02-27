require "dev-cmd/audit"
require "formulary"

RSpec::Matchers.alias_matcher :have_data, :be_data
RSpec::Matchers.alias_matcher :have_end, :be_end
RSpec::Matchers.alias_matcher :have_trailing_newline, :be_trailing_newline

describe FormulaText do
  let(:dir) { @dir = Pathname.new(Dir.mktmpdir) }

  after(:each) do
    dir.rmtree unless @dir.nil?
  end

  def formula_text(name, body = nil, options = {})
    path = dir/"#{name}.rb"

    path.write <<-EOS.undent
      class #{Formulary.class_s(name)} < Formula
        #{body}
      end
      #{options[:patch]}
    EOS

    described_class.new(path)
  end

  specify "simple valid Formula" do
    ft = formula_text "valid", <<-EOS.undent
      url "http://www.example.com/valid-1.0.tar.gz"
    EOS

    expect(ft).not_to have_data
    expect(ft).not_to have_end
    expect(ft).to have_trailing_newline

    expect(ft =~ /\burl\b/).to be_truthy
    expect(ft.line_number(/desc/)).to be nil
    expect(ft.line_number(/\burl\b/)).to eq(2)
    expect(ft).to include("Valid")
  end

  specify "#trailing_newline?" do
    ft = formula_text "newline"
    expect(ft).to have_trailing_newline
  end

  specify "#data?" do
    ft = formula_text "data", <<-EOS.undent
      patch :DATA
    EOS

    expect(ft).to have_data
  end

  specify "#end?" do
    ft = formula_text "end", "", patch: "__END__\na patch here"
    expect(ft).to have_end
    expect(ft.without_patch).to eq("class End < Formula\n  \nend")
  end
end
