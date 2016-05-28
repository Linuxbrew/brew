def deep_merge_hashes(hash1, hash2)
  merger = proc do |key, v1, v2|
    if Hash === v1 && Hash === v2
      v1.merge v2, &merger
    else
      v2
    end
  end
  hash1.merge hash2, &merger
end
