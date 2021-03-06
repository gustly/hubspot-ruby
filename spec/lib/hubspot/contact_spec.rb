require 'spec_helper'

describe Hubspot::Contact do
  let(:example_contact_hash) do
    VCR.use_cassette("contact_example", record: :none) do
      HTTParty.get("https://api.hubapi.com/contacts/v1/contact/email/testingapis@hubspot.com/profile?hapikey=demo").parsed_response
    end
  end
  let(:apikey) { "demo" }

  before{ Hubspot.configure(hapikey: apikey) }

  describe "#initialize" do
    subject{ Hubspot::Contact.new(example_contact_hash) }
    it{ should be_an_instance_of Hubspot::Contact }
    its(["email"]){ should == "testingapis@hubspot.com" }
    its(["firstname"]){ should == "Clint" }
    its(["lastname"]){ should == "Eastwood" }
    its(["phone"]){ should == "555-555-5432" }
    its(:utk){ should == "1234567890" }
    its(:vid){ should == 82325 }
  end

  describe ".create!" do
    cassette "contact_create"
    let(:params){{}}
    subject{ Hubspot::Contact.create!(email, params) }
    context "with a new email" do
      let(:email){ "newcontact#{Time.now.to_i}@hsgem.com" }
      it{ should be_an_instance_of Hubspot::Contact }
      its(:email){ should match /newcontact.*@hsgem.com/ } # Due to VCR the email may not match exactly

      context "and some params" do
        cassette "contact_create_with_params"
        let(:email){ "newcontact_x_#{Time.now.to_i}@hsgem.com" }
        let(:params){ {firstname: "Hugh", lastname: "Jackman" } }
        its(["firstname"]){ should == "Hugh"}
        its(["lastname"]){ should == "Jackman"}
      end
    end
    context "with an existing email" do
      cassette "contact_create_existing_email"
      let(:email){ "testingapis@hubspot.com" }
      it "raises a ContactExistsError" do
        expect{ subject }.to raise_error Hubspot::ContactExistsError
      end
    end
    context "with an invalid email" do
      cassette "contact_create_invalid_email"
      let(:email){ "not_an_email" }
      it "raises a RequestError" do
        expect{ subject }.to raise_error Hubspot::RequestError
      end
    end
  end

  describe ".find_by_email" do
    cassette "contact_find_by_email"
    subject{ Hubspot::Contact.find_by_email(email) }

    context "when the contact is found" do
      let(:email){ "testingapis@hubspot.com" }
      it{ should be_an_instance_of Hubspot::Contact }
      its(:vid){ should == 82325 }
    end

    context "when the contact cannot be found" do
      let(:email){ "notacontact@test.com" }
      it{ should be_nil }
    end
  end

  describe ".find_by_id" do
    cassette "contact_find_by_id"
    subject{ Hubspot::Contact.find_by_id(vid) }

    context "when the contact is found" do
      let(:vid){ 82325 }
      it{ should be_an_instance_of Hubspot::Contact }
      its(:email){ should == "testingapis@hubspot.com" }
    end

    context "when the contact cannot be found" do
      let(:vid){ 9999999 }
      it{ should be_nil }
    end
  end

  describe ".find_by_utk" do
    cassette "contact_find_by_utk"
    subject{ Hubspot::Contact.find_by_utk(utk) }

    context "when the contact is found" do
      let(:utk){ "f844d2217850188692f2610c717c2e9b" }
      it{ should be_an_instance_of Hubspot::Contact }
      its(:utk){ should == "f844d2217850188692f2610c717c2e9b" }
    end

    context "when the contact cannot be found" do
      let(:utk){ "invalid" }
      it{ should be_nil }
    end
  end

  describe ".all" do
    cassette "contact_all"

    describe "without count param" do
      subject{ Hubspot::Contact.all }

      context "when response is successful" do

        it "returns an array of contacts" do
          expect(subject.count).to eq(20)
        end
      end

      context "when response is not successful" do
        let(:apikey) { "bad_api_key" }
        it "raises a HubSpot APi Error" do
          expect{ subject }.to raise_error Hubspot::APIError
        end
      end
    end

    describe "with count param" do
      subject{ Hubspot::Contact.all(count) }
      let(:count) { 50 }
      it "returns an array of contacts" do
        expect(subject.count).to eq(50)
      end
    end
  end

  describe "#update!" do
    cassette "contact_update"
    let(:contact){ Hubspot::Contact.new(example_contact_hash) }
    let(:params){ {firstname: "Steve", lastname: "Cunningham"} }
    subject{ contact.update!(params) }

    it{ should be_an_instance_of Hubspot::Contact }
    its(["firstname"]){ should ==  "Steve" }
    its(["lastname"]){ should ==  "Cunningham" }

    context "when the request is not successful" do
      let(:contact){ Hubspot::Contact.new({"vid" => "invalid", "properties" => {}})}
      it "raises an error" do
        expect{ subject }.to raise_error Hubspot::RequestError
      end
    end
  end

  describe "#destroy!" do
    cassette "contact_destroy"
    let(:contact){ Hubspot::Contact.create!("newcontact_y_#{Time.now.to_i}@hsgem.com") }
    subject{ contact.destroy! }
    it { should be_true }
    it "should be destroyed" do
      subject
      contact.destroyed?.should be_true
    end
    context "when the request is not successful" do
      let(:contact){ Hubspot::Contact.new({"vid" => "invalid", "properties" => {}})}
      it "raises an error" do
        expect{ subject }.to raise_error Hubspot::RequestError
        contact.destroyed?.should be_false
      end
    end
  end

  describe "#destroyed?" do
    let(:contact){ Hubspot::Contact.new(example_contact_hash) }
    subject{ contact }
    its(:destroyed?){ should be_false }
  end
end
