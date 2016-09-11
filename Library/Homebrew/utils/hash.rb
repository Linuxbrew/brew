def deep_merge_hashes(hash1, hash2)
  merger = proc do |_key, v1, v2|
    if v1.is_a?(Hash) && v2.is_a?(Hash)
      v1.merge v2, &merger
    else
      v2
    end
  end
  hash1.merge hash2, &merger
end
