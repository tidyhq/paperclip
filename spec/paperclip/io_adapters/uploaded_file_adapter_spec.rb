require 'spec_helper'

describe Paperclip::UploadedFileAdapter do
  context "a new instance" do
    context "with UploadedFile responding to #tempfile" do
      before do
        Paperclip::UploadedFileAdapter.content_type_detector = nil

        class UploadedFile < OpenStruct; end
        tempfile = File.new(fixture_file("5k.png"))
        tempfile.binmode

        @file = UploadedFile.new(
          original_filename: "5k.png",
          content_type: "image/x-png-by-browser\r",
          head: "",
          tempfile: tempfile,
          path: tempfile.path
        )
        @subject = Paperclip.io_adapters.for(@file)
      end

      it "get the right filename" do
        assert_equal "5k.png", @subject.original_filename
      end

      it "force binmode on tempfile" do
        assert @subject.instance_variable_get("@tempfile").binmode?
      end

      it "get the content type" do
        assert_equal "image/x-png-by-browser", @subject.content_type
      end

      it "get the file's size" do
        assert_equal 4456, @subject.size
      end

      it "return false for a call to nil?" do
        assert ! @subject.nil?
      end

      it "generate a MD5 hash of the contents" do
        expected = Digest::MD5.file(@file.tempfile.path).to_s
        assert_equal expected, @subject.fingerprint
      end

      it "read the contents of the file" do
        expected = @file.tempfile.read
        assert expected.length > 0
        assert_equal expected, @subject.read
      end
    end

    context "with UploadedFile that has restricted characters" do
      before do
        Paperclip::UploadedFileAdapter.content_type_detector = nil

        class UploadedFile < OpenStruct; end
        @file = UploadedFile.new(
          original_filename: "image:restricted.gif",
          content_type: "image/x-png-by-browser",
          head: "",
          path: fixture_file("5k.png")
        )
        @subject = Paperclip.io_adapters.for(@file)
      end

      it "not generate paths that include restricted characters" do
        expect(@subject.path).to_not match(/:/)
      end

      it "not generate filenames that include restricted characters" do
        assert_equal 'image_restricted.gif', @subject.original_filename
      end
    end

    context "with UploadFile responding to #path" do
      before do
        Paperclip::UploadedFileAdapter.content_type_detector = nil

        class UploadedFile < OpenStruct; end
        @file = UploadedFile.new(
          original_filename: "5k.png",
          content_type: "image/x-png-by-browser",
          head: "",
          path: fixture_file("5k.png")
        )
        @subject = Paperclip.io_adapters.for(@file)
      end

      it "get the right filename" do
        assert_equal "5k.png", @subject.original_filename
      end

      it "force binmode on tempfile" do
        assert @subject.instance_variable_get("@tempfile").binmode?
      end

      it "get the content type" do
        assert_equal "image/x-png-by-browser", @subject.content_type
      end

      it "get the file's size" do
        assert_equal 4456, @subject.size
      end

      it "return false for a call to nil?" do
        assert ! @subject.nil?
      end

      it "generate a MD5 hash of the contents" do
        expected = Digest::MD5.file(@file.path).to_s
        assert_equal expected, @subject.fingerprint
      end

      it "read the contents of the file" do
        expected_file = File.new(@file.path)
        expected_file.binmode
        expected = expected_file.read
        assert expected.length > 0
        assert_equal expected, @subject.read
      end

      context "don't trust client-given MIME type" do
        before do
          Paperclip::UploadedFileAdapter.content_type_detector =
            Paperclip::FileCommandContentTypeDetector

          class UploadedFile < OpenStruct; end
          @file = UploadedFile.new(
            original_filename: "5k.png",
            content_type: "image/x-png-by-browser",
            head: "",
            path: fixture_file("5k.png")
          )
          @subject = Paperclip.io_adapters.for(@file)
        end

        it "get the content type" do
          assert_equal "image/png", @subject.content_type
        end
      end
    end
  end
end