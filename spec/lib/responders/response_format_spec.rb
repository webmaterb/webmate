require 'spec_helper'

# trying to wrap this-file-specific examples to module
module ResponseFormatSpec
  class ExampleBase
    include Webmate::Responders::ResponseFormat
    respond_to :json, :html, :xml, :yml, :default => :json
  end

  class Parent < ExampleBase
  end

  class Child < Parent
    respond_to :json, :html, :default => :json
  end

  class SubChild < Child
  end

  class ExampleResponder
    include Webmate::Responders::ResponseFormat
    respond_to :json, :html, :default => :json
    attr_accessor :params

    def initialize(args = {})
      @params = args
    end
  end
end

describe Webmate::Responders::ResponseFormat do
  context "format settings" do
    it "should be setted" do
      settings = ResponseFormatSpec::ExampleBase.format_settings
      settings[:formats].should =~ [:json, :html, :xml, :yml]
      settings[:default].should eq(:json)
    end

    it "should be inherited" do
      settings = ResponseFormatSpec::Parent.format_settings
      settings[:formats].should =~ [:json, :html, :xml, :yml]
      settings[:default].should eq(:json)
    end

    it "should be able to rewrite in siblings" do
      settings = ResponseFormatSpec::Child.format_settings
      settings[:formats].should =~ [:json, :html]
      settings[:default].should eq(:json)
    end

    it "should inherit rewrited setttings" do
      settings = ResponseFormatSpec::SubChild.format_settings
      settings[:formats].should =~ [:json, :html]
      settings[:default].should eq(:json)
    end
  end

  context "convert to request format" do
    let(:mock_response) { double('mock_response') }
    let(:result) { double('converted_result') }

    it "should convert response to params[:format]" do
      mock_response.should_receive(:to_html).and_return(result)

      responder = ResponseFormatSpec::ExampleResponder.new(format: 'html')
      responder.convert_to_request_format(mock_response).should eq(result)
    end

    it "should use default format if format unknown" do
      mock_response.should_receive(:to_json).and_return(result)

      responder = ResponseFormatSpec::ExampleResponder.new(format: 'some unknown format')
      responder.convert_to_request_format(mock_response).should eq(result)
    end

    it "should use default format if format blank" do
      mock_response.should_receive(:to_json).and_return(result)

      responder = ResponseFormatSpec::ExampleResponder.new
      responder.convert_to_request_format(mock_response).should eq(result)
    end
  end
end
