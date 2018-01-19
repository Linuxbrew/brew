class ScriptFileFormula < Formula
  def install
    odisabled "ScriptFileFormula#install", "Formula#install"
  end
end

class GithubGistFormula < ScriptFileFormula
  def self.url(_val)
    odisabled "GithubGistFormula.url", "Formula.url"
  end
end

class AmazonWebServicesFormula < Formula
  def install
    odisabled "AmazonWebServicesFormula#install", "Formula#install"
  end
  alias standard_install install

  # Use this method to generate standard caveats.
  def standard_instructions(_, _)
    odisabled "AmazonWebServicesFormula#standard_instructions", "Formula#caveats"
  end
end
