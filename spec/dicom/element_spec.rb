# encoding: UTF-8

require 'spec_helper'


module DICOM

  describe Element do

    context "::new" do

      it "should raise ArgumentError when creation is attempted with an invalid tag string" do
        expect {Element.new("asdf,asdf", 42)}.to raise_error(ArgumentError)
      end

      it "should raise ArgumentError when creation is attempted with a non-string as tag" do
        expect {Element.new(3.1337, 42)}.to raise_error(ArgumentError)
      end

      it "should set its value attribute on creation" do
        d = Element.new("0028,0010", 512)
        d.value.should eql 512
      end

      it "should get its name attribute from the dictionary on creation" do
        d = Element.new("0028,0010", 512)
        d.name.should eql "Rows"
      end

      it "should correctly set its length attribute on creation" do
        d = Element.new("0028,0010", 512)
        d.length.should eql 2
      end

      it "should correctly encode its value to a binary string on creation" do
        d = Element.new("0018,1310", 512)
        d.bin.should eql "\000\002"
      end

      it "should correctly encode an integer value placed in an array to the known binary string of this integer" do
        d = Element.new("0018,1310", [512])
        d.bin.should eql "\000\002"
      end

      it "should correctly encode multiple integer values placed in an array to the known binary string of these integers" do
        d = Element.new("0018,1310", [512, 512])
        d.bin.should eql "\000\002\000\002"
      end

      it "should get its VR attribute from the dictionary on creation" do
        d = Element.new("0028,0010", 512)
        d.vr.should eql "US"
      end

      it "should set its tag attribute on creation" do
        d = Element.new("0028,0010", 512)
        d.tag.should eql "0028,0010"
      end

      it "should set its parent attribute to nil when no parent is specified" do
        d = Element.new("0028,0010", 512)
        d.parent.should be_nil
      end

      it "should set the parent attribute when the :parent option is used on creation" do
        i = Item.new
        d = Element.new("3006,0084", "1", :parent => i)
        d.parent.should eql i
      end

      it "should update the parent attribute when the parent=() method is called" do
        i = Item.new
        d = Element.new("3006,0084", "1", :parent => i)
        d.parent = i
        d.parent.should eql i
      end

      it "should register itself as a child of the new parent element when the parent=() method is called" do
        i = Item.new
        d = Element.new("3006,0084", "1")
        d.parent = i
        i.children?.should eql true
      end

      it "should remove itself as a child of the old parent element when a new parent is set to a child which already has a parent" do
        i_old = Item.new
        d = Element.new("3006,0084", "1", :parent => i_old)
        i_new = Item.new
        d.parent = i_new
        i_old.children?.should be_false
      end

      it "should add itself as a child of the new parent element when a new parent is set to a child which already has a parent" do
        i_old = Item.new
        d = Element.new("3006,0084", "1", :parent => i_old)
        i_new = Item.new
        d.parent = i_new
        i_new.children?.should be_true
      end

      it "should remove itself as a child of the old parent element when parent is set as nil" do
        i = Item.new
        d = Element.new("3006,0084", "1", :parent => i)
        d.parent = nil
        i.children?.should be_false
      end

      it "should keep its parent and the parent should keep its child if the existing parent is set with the parent=() method" do
        i = Item.new
        d = Element.new("3006,0084", "1", :parent => i)
        d.parent = i
        i.count.should eql 1
        d.parent.should eql i
      end

      it "should return an empty array when the parents method is called and no parent has been specified" do
        d = Element.new("0028,0010", 512)
        d.parents.should eql Array.new
      end

      it "should return a 3-element array with the chain of parents, where the top parent is the last element, and immediate parent is the first" do
        dcm = DObject.new
        s = Sequence.new("3006,0040", :parent => dcm)
        i = Item.new(:parent => s)
        d = Element.new("3006,0084", "1", :parent => i)
        d.parents.length.should eql 3
        d.parents.first.should eql i
        d.parents.last.should eql dcm
      end

      it "should return itself when the top_parent method is called and no external parent has been specified" do
        d = Element.new("0028,0010", 512)
        d.top_parent.should eql d
      end

      it "should return the top parent in the chain of parents when the top_parent method is called on an element with multiple parents" do
        dcm = DObject.new
        s = Sequence.new("3006,0040", :parent => dcm)
        i = Item.new(:parent => s)
        d = Element.new("3006,0084", "1", :parent => i)
        d.top_parent.should eql dcm
      end

      it "should return a Stream instance when the stream method is called" do
        d = Element.new("0028,0010", 512)
        d.stream.class.should == Stream
      end

      it "should use the pre-encoded string as binary if indicated by option on creation" do
        d = Element.new("0028,0010", "\000\002", :encoded => true)
        d.bin.should eql "\000\002"
      end

      it "should not set the value attribute when given a pre-encoded string on creation" do
        d = Element.new("0028,0010", "\000\002", :encoded => true)
        d.value.should be_nil
      end

      it "should use the binary (supplied as an option) instead of encoding the value on creation" do
        d = Element.new("0028,0010", 3, :bin => "\000\002")
        d.bin.should eql "\000\002"
      end

      it "should set the value attribute when an optional binary string is supplied on creation" do
        d = Element.new("0028,0010", 3, :bin => "\000\002")
        d.value.should eql 3
      end

      it "should use the name (supplied as an option), rather than the matching dictionary entry, on creation" do
        d = Element.new("0028,0010", 512, :name => "Custom Rows")
        d.name.should eql "Custom Rows"
      end

      it "should use the VR (supplied as an option), rather than the matching dictionary entry, on creation" do
        d = Element.new("0028,0010", 512, :vr => "UL")
        d.vr.should eql "UL"
      end

      it "should correctly encode the binary, using the VR supplied as an option, on creation" do
        d = Element.new("0028,0010", 512, :vr => "UL")
        d.bin.should eql "\000\002\000\000"
      end

      it "should correctly encode the binary of a private data element, using the VR supplied as an option, on creation" do
        d = Element.new("0029,0010", 512, :vr => "UL")
        d.bin.should eql "\000\002\000\000"
      end

      it "should set the name attribute as 'Private' when a private tag is created" do
        d = Element.new("0029,0010", 512, :vr => "UL")
        d.name.should eql "Private"
      end

      it "should set the name attribute as 'Unknown' when a non-private tag is created that can't be matched in the dictionary" do
        d = Element.new("ABF0,1234", 512, :vr => "UL")
        d.name.should eql "Unknown"
      end

      it "should raise ArgumentError when a non-string is passed to the bin=() method" do
        d = Element.new("0028,0010", 512)
        expect {d.bin = 512}.to raise_error(ArgumentError)
      end

      it "should update the data element's binary when the bin=() method is called" do
        d = Element.new("0028,0010", 512)
        d.bin = "\000\003"
        d.bin.should eql "\000\003"
      end

      it "should pad the binary when the bin=() method is called with a string of odd length" do
        d = Element.new("0028,0010", 512)
        d.bin = "odd"
        d.bin.length.should eql 4
      end

      it "should correctly set the length attribute when the bin=() method is called with a string of odd length" do
        d = Element.new("0028,0010", 512)
        d.bin = "odd"
        d.length.should eql 4
      end

      it "should correctly update the length attribute when the value=() method is called" do
        d = Element.new("0010,0010", "Name")
        d.value = "LongName"
        d.length.should eql 8
      end

      it "should pad the binary when the value=() method is called with a string of odd length" do
        d = Element.new("0010,0010", "Name")
        d.value = "OddName"
        d.bin.length.should eql 8
      end

      it "should update the value attribute when the value=() method is called" do
        d = Element.new("0010,0010", "Name")
        d.value = "John"
        d.value.should eql "John"
      end

      it "should correctly set the length attribute when the binary=() method is called with a string of odd length" do
        d = Element.new("0010,0010", "Name")
        d.value = "OddName"
        d.length.should eql 8
      end

      it "should return false when the children? method is called as an Element do not have child elements" do
        d = Element.new("0028,0010", 512)
        d.children?.should be_false
      end

      it "should return false when the is_parent? method is called as an Element is never a parent element" do
        d = Element.new("0028,0010", 512)
        d.is_parent?.should be_false
      end

      it "should use little endian as default encoding, and report this as false when the endian method is called" do
        d = Element.new("0028,0010", 512)
        d.endian.should be_false
      end

      it "should convert the value of an Element of value representation 'BY' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'BY')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'US' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'US')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'SS' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'SS')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'UL' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'UL')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'SL' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'SL')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'OB' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'OB')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'OW' to Integer" do
        e = Element.new("0021,0001", '42', :vr => 'OW')
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'OF' to Float" do
        e = Element.new("0021,0001", '42.0', :vr => 'OF')
        e.value.should eql 42.0
      end

      it "should convert the value of an Element of value representation 'FL' to Float" do
        e = Element.new("0021,0001", '42.0', :vr => 'FL')
        e.value.should eql 42.0
      end

      it "should convert the value of an Element of value representation 'FD' to Float" do
        e = Element.new("0021,0001", '42.0', :vr => 'FD')
        e.value.should eql 42.0
      end

      it "should convert the value of an Element of value representation 'AT' to String" do
        # This example is somewhat artificial as this symbol doesn't convert to a valid tag string.
        e = Element.new("0021,0001", :ABCD_ABCD, :vr => 'AT')
        e.value.should eql 'ABCD_ABCD'
      end

      it "should convert the value of an Element of value representation 'AE' to String" do
        e = Element.new("0021,0001", 42, :vr => 'AE')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'AS' to String" do
        e = Element.new("0021,0001", 42, :vr => 'AS')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'CS' to String" do
        e = Element.new("0021,0001", 42, :vr => 'CS')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'DA' to String" do
        e = Element.new("0021,0001", 42, :vr => 'DA')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'DS' to String" do
        e = Element.new("0021,0001", 42, :vr => 'DS')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'DT' to String" do
        e = Element.new("0021,0001", 42, :vr => 'DT')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'IS' to String" do
        e = Element.new("0021,0001", 42, :vr => 'IS')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'LO' to String" do
        e = Element.new("0021,0001", 42, :vr => 'LO')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'LT' to String" do
        e = Element.new("0021,0001", 42, :vr => 'LT')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'PN' to String" do
        e = Element.new("0021,0001", 42, :vr => 'PN')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'SH' to String" do
        e = Element.new("0021,0001", 42, :vr => 'SH')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'ST' to String" do
        e = Element.new("0021,0001", 42, :vr => 'ST')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'TM' to String" do
        e = Element.new("0021,0001", 42, :vr => 'TM')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'UI' to String" do
        e = Element.new("0021,0001", 42, :vr => 'UI')
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'UT' to String" do
        e = Element.new("0021,0001", 42, :vr => 'UT')
        e.value.should eql '42'
      end

      it "should by default convert to string when dealing with an Element of unknown value representation" do
        e = Element.new("0021,0001", 42)
        e.value.should eql '42'
      end

    end


    describe "#==()" do

      it "should be true when comparing two instances having the same attribute values" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0010", 512)
        (e1 == e2).should be_true
      end

      it "should be false when comparing two instances having different attribute values (same tag but different values)" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0010", 510)
        (e1 == e2).should be_false
      end

      it "should be false when comparing two instances having different attribute values (different tag but same value/vr)" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0011", 512)
        (e1 == e2).should be_false
      end

      it "should be false when comparing against an instance of incompatible type" do
        e = Element.new("0028,0010", 512)
        (e == 42).should be_false
      end

    end


    describe "#eql?" do

      it "should be true when comparing two instances having the same attribute values" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0010", 512)
        e1.eql?(e2).should be_true
      end

      it "should be false when comparing two instances having different attribute values" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0010", 510)
        e1.eql?(e2).should be_false
      end

    end


    describe "#hash" do

      it "should return the same Fixnum for two instances having the same attribute values" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0010", 512)
        e1.hash.should eql e2.hash
      end

      it "should return a different Fixnum for two instances having different attribute values" do
        e1 = Element.new("0028,0010", 512)
        e2 = Element.new("0028,0010", 510)
        e1.hash.should_not eql e2.hash
      end

    end


    describe "#to_element" do

      it "should return itself" do
        e = Element.new("0028,0010", 512)
        e.to_element.equal?(e).should be_true
      end

    end


    describe "#value=()" do

      it "should convert the value of an Element of value representation 'BY' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'BY')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'US' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'US')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'SS' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'SS')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'UL' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'UL')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'SL' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'SL')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'OB' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'OB')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'OW' to Integer" do
        e = Element.new("0021,0001", 0, :vr => 'OW')
        e.value = '42'
        e.value.should eql 42
      end

      it "should convert the value of an Element of value representation 'OF' to Float" do
        e = Element.new("0021,0001", 0.0, :vr => 'OF')
        e.value = '42.0'
        e.value.should eql 42.0
      end

      it "should convert the value of an Element of value representation 'FL' to Float" do
        e = Element.new("0021,0001", 0.0, :vr => 'FL')
        e.value = '42.0'
        e.value.should eql 42.0
      end

      it "should convert the value of an Element of value representation 'FD' to Float" do
        e = Element.new("0021,0001", 0.0, :vr => 'FD')
        e.value = '42.0'
        e.value.should eql 42.0
      end

      it "should convert the value of an Element of value representation 'AT' to String" do
        e = Element.new("0021,0001", '3004,000C', :vr => 'AT')
        # This example is somewhat artificial as this symbol doesn't convert to a valid tag string.
        e.value = :ABCD_ABCD
        e.value.should eql 'ABCD_ABCD'
      end

      it "should convert the value of an Element of value representation 'AE' to String" do
        e = Element.new("0021,0001", '', :vr => 'AE')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'AS' to String" do
        e = Element.new("0021,0001", '', :vr => 'AS')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'CS' to String" do
        e = Element.new("0021,0001", '', :vr => 'CS')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'DA' to String" do
        e = Element.new("0021,0001", '', :vr => 'DA')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'DS' to String" do
        e = Element.new("0021,0001", '', :vr => 'DS')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'DT' to String" do
        e = Element.new("0021,0001", '', :vr => 'DT')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'IS' to String" do
        e = Element.new("0021,0001", '', :vr => 'IS')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'LO' to String" do
        e = Element.new("0021,0001", '', :vr => 'LO')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'LT' to String" do
        e = Element.new("0021,0001", '', :vr => 'LT')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'PN' to String" do
        e = Element.new("0021,0001", '', :vr => 'PN')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'SH' to String" do
        e = Element.new("0021,0001", '', :vr => 'SH')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'ST' to String" do
        e = Element.new("0021,0001", '', :vr => 'ST')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'TM' to String" do
        e = Element.new("0021,0001", '', :vr => 'TM')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'UI' to String" do
        e = Element.new("0021,0001", '', :vr => 'UI')
        e.value = 42
        e.value.should eql '42'
      end

      it "should convert the value of an Element of value representation 'UT' to String" do
        e = Element.new("0021,0001", '', :vr => 'UT')
        e.value = 42
        e.value.should eql '42'
      end

      it "should by default convert to string when dealing with an Element of unknown value representation" do
        e = Element.new("0021,0001", '')
        e.value = 42
        e.value.should eql '42'
      end

    end

  end

end