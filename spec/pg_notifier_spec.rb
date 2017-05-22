require "spec_helper"

RSpec.describe PgNotifier do
  it "has a version number" do
    expect(PgNotifier::VERSION).not_to be nil
  end
end
