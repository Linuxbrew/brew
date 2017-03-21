require "testing_env"
require "migrator"
require "test/support/fixtures/testball"
require "tab"
require "keg"

class Formula
  attr_writer :oldname
end

class MigratorErrorsTests < Homebrew::TestCase
  def setup
    super
    @new_f = Testball.new("newname")
    @new_f.oldname = "oldname"
    @old_f = Testball.new("oldname")
  end

  def test_no_oldname
    assert_raises(Migrator::MigratorNoOldnameError) { Migrator.new(@old_f) }
  end

  def test_no_oldpath
    assert_raises(Migrator::MigratorNoOldpathError) { Migrator.new(@new_f) }
  end

  def test_different_taps
    keg = HOMEBREW_CELLAR/"oldname/0.1"
    keg.mkpath
    tab = Tab.empty
    tab.tabfile = HOMEBREW_CELLAR/"oldname/0.1/INSTALL_RECEIPT.json"
    tab.source["tap"] = "homebrew/core"
    tab.write
    assert_raises(Migrator::MigratorDifferentTapsError) { Migrator.new(@new_f) }
  end
end

class MigratorTests < Homebrew::TestCase
  include FileUtils

  def setup
    super

    @new_f = Testball.new("newname")
    @new_f.oldname = "oldname"

    @old_f = Testball.new("oldname")

    @old_keg_record = HOMEBREW_CELLAR/"oldname/0.1"
    @old_keg_record.join("bin").mkpath
    @new_keg_record = HOMEBREW_CELLAR/"newname/0.1"

    %w[inside bindir].each { |file| touch @old_keg_record.join("bin", file) }

    @old_tab = Tab.empty
    @old_tab.tabfile = HOMEBREW_CELLAR/"oldname/0.1/INSTALL_RECEIPT.json"
    @old_tab.source["path"] = "/oldname"
    @old_tab.write

    @keg = Keg.new(@old_keg_record)
    @keg.link
    @keg.optlink

    @old_pin = HOMEBREW_PINNED_KEGS/"oldname"
    @old_pin.make_relative_symlink @old_keg_record

    @migrator = Migrator.new(@new_f)

    mkpath HOMEBREW_PREFIX/"bin"
  end

  def teardown
    if !@old_keg_record.parent.symlink? && @old_keg_record.directory?
      @keg.unlink
    end

    if @new_keg_record.directory?
      new_keg = Keg.new(@new_keg_record)
      new_keg.unlink
    end

    super
  end

  def test_move_cellar
    @keg.unlink
    shutup { @migrator.move_to_new_directory }
    assert_predicate @new_keg_record, :directory?
    assert_predicate @new_keg_record/"bin", :directory?
    assert_predicate @new_keg_record/"bin/inside", :file?
    assert_predicate @new_keg_record/"bin/bindir", :file?
    refute_predicate @old_keg_record, :directory?
  end

  def test_backup_cellar
    @old_keg_record.parent.rmtree
    @new_keg_record.join("bin").mkpath

    @migrator.backup_oldname_cellar

    assert_predicate @old_keg_record, :directory?
    assert_predicate @old_keg_record/"bin", :directory?
  end

  def test_repin
    @new_keg_record.join("bin").mkpath
    expected_relative = @new_keg_record.relative_path_from HOMEBREW_PINNED_KEGS

    @migrator.repin

    assert_predicate @migrator.new_pin_record, :symlink?
    assert_equal expected_relative, @migrator.new_pin_record.readlink
    refute_predicate @migrator.old_pin_record, :exist?
  end

  def test_unlink_oldname
    assert_equal 1, HOMEBREW_LINKED_KEGS.children.size
    assert_equal 1, (HOMEBREW_PREFIX/"opt").children.size

    shutup { @migrator.unlink_oldname }

    refute_predicate HOMEBREW_LINKED_KEGS, :exist?
    refute_predicate HOMEBREW_LIBRARY/"bin", :exist?
  end

  def test_link_newname
    @keg.unlink
    @keg.uninstall
    @new_keg_record.join("bin").mkpath
    %w[inside bindir].each { |file| touch @new_keg_record.join("bin", file) }

    shutup { @migrator.link_newname }

    assert_equal 1, HOMEBREW_LINKED_KEGS.children.size
    assert_equal 1, (HOMEBREW_PREFIX/"opt").children.size
  end

  def test_link_oldname_opt
    @new_keg_record.mkpath
    @migrator.link_oldname_opt
    assert_equal @new_keg_record.realpath, (HOMEBREW_PREFIX/"opt/oldname").realpath
  end

  def test_link_oldname_cellar
    @new_keg_record.join("bin").mkpath
    @keg.unlink
    @keg.uninstall
    @migrator.link_oldname_cellar
    assert_equal @new_keg_record.parent.realpath, (HOMEBREW_CELLAR/"oldname").realpath
  end

  def test_update_tabs
    @new_keg_record.join("bin").mkpath
    tab = Tab.empty
    tab.tabfile = HOMEBREW_CELLAR/"newname/0.1/INSTALL_RECEIPT.json"
    tab.source["path"] = "/path/that/must/be/changed/by/update_tabs"
    tab.write
    @migrator.update_tabs
    assert_equal @new_f.path.to_s, Tab.for_keg(@new_keg_record).source["path"]
  end

  def test_migrate
    tab = Tab.empty
    tab.tabfile = HOMEBREW_CELLAR/"oldname/0.1/INSTALL_RECEIPT.json"
    tab.source["path"] = @old_f.path.to_s
    tab.write

    shutup { @migrator.migrate }

    assert_predicate @new_keg_record, :exist?
    assert_predicate @old_keg_record.parent, :symlink?
    refute_predicate HOMEBREW_LINKED_KEGS/"oldname", :exist?
    assert_equal @new_keg_record.realpath, (HOMEBREW_LINKED_KEGS/"newname").realpath
    assert_equal @new_keg_record.realpath, @old_keg_record.realpath
    assert_equal @new_keg_record.realpath, (HOMEBREW_PREFIX/"opt/oldname").realpath
    assert_equal @new_keg_record.parent.realpath, (HOMEBREW_CELLAR/"oldname").realpath
    assert_equal @new_keg_record.realpath, (HOMEBREW_PINNED_KEGS/"newname").realpath
    assert_equal @new_f.path.to_s, Tab.for_keg(@new_keg_record).source["path"]
  end

  def test_unlinik_oldname_opt
    @new_keg_record.mkpath
    old_opt_record = HOMEBREW_PREFIX/"opt/oldname"
    old_opt_record.unlink if old_opt_record.symlink?
    old_opt_record.make_relative_symlink(@new_keg_record)
    @migrator.unlink_oldname_opt
    refute_predicate old_opt_record, :symlink?
  end

  def test_unlink_oldname_cellar
    @new_keg_record.mkpath
    @keg.unlink
    @keg.uninstall
    @old_keg_record.parent.make_relative_symlink(@new_keg_record.parent)
    @migrator.unlink_oldname_cellar
    refute_predicate @old_keg_record.parent, :symlink?
  end

  def test_backup_oldname_cellar
    @new_keg_record.join("bin").mkpath
    @keg.unlink
    @keg.uninstall
    @migrator.backup_oldname_cellar
    refute_predicate @old_keg_record.subdirs, :empty?
  end

  def test_backup_old_tabs
    tab = Tab.empty
    tab.tabfile = HOMEBREW_CELLAR/"oldname/0.1/INSTALL_RECEIPT.json"
    tab.source["path"] = "/should/be/the/same"
    tab.write
    migrator = Migrator.new(@new_f)
    tab.tabfile.delete
    migrator.backup_old_tabs
    assert_equal "/should/be/the/same", Tab.for_keg(@old_keg_record).source["path"]
  end

  # Backup tests are divided into three groups: when oldname Cellar is deleted
  # and when it still exists and when it's a symlink

  def check_after_backup
    assert_predicate @old_keg_record.parent, :directory?
    refute_predicate @old_keg_record.parent.subdirs, :empty?
    assert_predicate HOMEBREW_LINKED_KEGS/"oldname", :exist?
    assert_predicate HOMEBREW_PREFIX/"opt/oldname", :exist?
    assert_predicate HOMEBREW_PINNED_KEGS/"oldname", :symlink?
    assert_predicate @keg, :linked?
  end

  def test_backup_cellar_exist
    @migrator.backup_oldname
    check_after_backup
  end

  def test_backup_cellar_removed
    @new_keg_record.join("bin").mkpath
    @keg.unlink
    @keg.uninstall
    @migrator.backup_oldname
    check_after_backup
  end

  def test_backup_cellar_linked
    @new_keg_record.join("bin").mkpath
    @keg.unlink
    @keg.uninstall
    @old_keg_record.parent.make_relative_symlink(@new_keg_record.parent)
    @migrator.backup_oldname
    check_after_backup
  end
end
