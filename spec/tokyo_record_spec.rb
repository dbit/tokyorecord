require 'rubygems'
require 'spec/spec_helper'
require 'ftools'
require 'tokyo_record'

# If you're not used to doing tests with RSpec, try http://www.ibm.com/developerworks/web/library/wa-rspec/

describe 'TokyoRecord module' do
  
    before :each do
      class User 
        include TokyoRecord
      end
      @user = User.new
    end
  
    after :each do
      # Remove all of the TC databases after all the tests are over.
      [ "User.id.bdb",
        "Post.id.bdb",                     # `Id` attributes just keep track of the last insert id for each class.
                      "User.age.bdb", "User.age.fdb",         # Each non-`id` attribute has a bdb, for fast O(log n) searches by value, 
                      "User.name.bdb","User.name.fdb",        #   and an fdb for fast O(1) look-ups by id.
                      "Post.title.bdb","Post.title.fdb",
                      "Post.user_id.bdb","Post.user_id.fdb"
       ].each do |file|
        begin
          File.delete( file )
        rescue => e
          # puts e
        end
        TokyoRecord.close_all
      end
    end


  describe "internal functions:" do

      describe "subclass_name" do
          it "should return 'User'" do
            @user.subclass_name.should be ==( 'User' )
          end
      end # subclass_name

      describe "id_db_name" do
          it "should return 'User.id.bdb'" do
            @user.id_db_name.should be == 'User.id.bdb'
          end
      end

      describe "self.id_db_name" do
          it "should return 'User.id.bdb'" do 
            User.id_db_name.should match( /User.id.bdb/ )        
          end
      end

      describe "after initialization," do

          it "should create a file handle to User.id.bdb" do
            @user.id_db.should be_an_instance_of( TokyoCabinet::BDB )
          end

          it "should write a file to disk called 'User.id.bdb'" do
            File.exist?( "User.id.bdb" ). should be_true
          end
          
      end  # after initialization
  end # internal functions

  describe "initial state (of, for example, a User model) when NOT declaring anything," do

    it "should have exactly one file handle( User.id.bdb ) when there haven't yet been any properties declared." do
      TokyoRecord.file_handles.size.to_i. should == ( 1 )
    end

    it "should not, for example, have a User.name.bdb file on disk." do
      File.exist?( "User.name.bdb" ). should be_false      
    end

    it "should raise a NoSuchAttribute error if the attribute 'name' hasn't been declared yet and you try to create a persisted instance of the object." do
      lambda {
        User.create( :name => 'Dustin') 
      }. should raise_error( NoSuchAttribute )
    end    

    it "should raise a NoSuchAttribute error if a non-existant attribute is attempted to be accessed" do
      begin
         @user.fudge
      end. should raise_error( NoSuchAttribute )
    end

  end # describe initial state

  describe "tokyo ids" do

    it "should be nil if not saved yet." do
      @user.tid.should be_nil( 'tid' )
    end      

    it "should have a next_id of 1" do
      User.next_id. should == 1
    end

    it "should have a positive integer tid after it is saved." do
      @user.save
      @user.tid. should be == 1
    end

    it "should create a new row with an id of 1 in User.id.bdb if an instance is saved." do
      @user.save  # N.B. There is no persistence between RSpec tests.
      User.next_id. should == 2
    end

  end # tokyo ids

  describe "declaring a single attribute called 'name'" do

    before :each do
      class User 
        include TokyoRecord
        attributes :name
      end
      @user = User.new
    end

    it "should not raise a NoSuchAttribute error if the attribute 'name' has been declared already and if you try to create a persistent instance of the object." do
      begin 
        @user.name = 'Dustin'
        @user.save
      end. should_not_raise( NoSuchAttribute )
    end    

  end # 'declaring a single attribute'
end # TokyoRecord module
=begin

    describe "declaring a single attribute called 'name'" do

=begin      
      it "should create a bdb file if the attribute has been declared." do
        File.exist?( "User.name.bdb" ). should be_true
      end
      
      it "should create an fdb file if the attribute has been declared." do
        File.exist?( "User.name.fdb" ). should be_true
      end 

      it "should be able to resond to the 'name' message" do
        @user. should respond_to?( 'name' )
      end
      
      it "should be able to say 'name = something' " do
        # Make sure that the unsaved object can store values in the get and set methods.
        @user.name = 'David'
        @user.name. should be_equal( 'David' )
      end
      
      it "should not have a Tokyo id (id) yet since it is not yet saved." do
        @user.tid. should be_nil
      end
      
      describe "assigning values to the name atribute and saving it to the database" do

        before :each do
          @user.name = 'Donald Duck'
          @user.save
        end

        it "should be able to save the name value to the database and retrieve the value with a find method." do
          User.find( 1 ).name. should be_equal( 'Donald Duck' )
        end        

        it "should have a Tokyo id (tid) of 1." do
          @user.tid. should be_equal( 1 )
        end
        
        it "should have incremented the next id value to 2" do
          User.next_id. should be_equal( 2 )
        end
        
      end # end describe
            
    end

    describe "Subclassed instances with properties called 'name' and 'age'." do
      
      before :each do
        class User 
          include TokyoRecord
          attributes :name, :age
        end
        @user = User.new
      end
            
      it "should respond to the name= assignment operator." do
        @user. should respond_to?( 'name=' )
      end

      it "should respond to the age= assignment operator." do
        @user. should respond_to?( 'age=' )
      end
      
      it "should not have an tid (Tokyo Cabinet Id) before it is saved." do
        @user.tid. should be_null 
      end
      

      it "should not store the attribute in the database before you call save." do
        @user.name = 'David'
        User.find_by_name( 'David' ). should be_empty
      end

      it "should store the attribute in the database after you call save." do
        @user.name = 'David'
        @user.save
        User.find_by_name( 'David' ). should be_equal( 'David' )
      end

      it "should be able create new instances by passing in a hash with keys of :name and :age." do
        @user = User.create( :name => "David", :age => 36 )
        @user.name. should be_equal( 'David' )
        @user.age. should be_equal( 36 )
      end


    end # end describe subclassed instances with a property called 'name'
  
    describe "Find methods" do
      # Find by id
      # Find :all
      # Find_by_attribute
      
      before :each do
        class User 
          include TokyoRecord
          attributes :name
        end
        User.create( :name => 'Beckwith', :age => 36)
        User.create( :name => 'Inoue', :age => 25)
        
      end
      
      it "should return an instance of the User class when searching for the record with an id of 1." do
        User.find( 1 ). should be_an_instance_of( User )
      end

      it "should return an instance of the User class when searching for the record with an id of 1." do
        User.find( 1 ).name. should be_equal( 'Beckwith' )
      end
      
      it "should return an array when calling User.find( :all )" do
        User.find( :all ). should be_a_kind_of( Array )
      end

      it "should return an array which contains an instance whose name is 'Beckwith' when calling find( :all )." do
        User.find( :all ).find { |u| u.name == 'Beckwith' }. should_not be_nil
      end

      it "should return an instance of class User when calling find_by_name( 'Beckwith' )." do
        User.find_by_name( 'Beckwith' ). should be_an_instance_of( User )
      end
      
      it "should return an object when sending the 'name' message to it." do
        User.find_by_name( 'Beckwith' ).name. should be_equal( 'Beckwith' )
      end
      
      it "should return an array when calling User.find( :all )." do
        User.find( :all ). should be_a_kind_of( Array )
      end

      it "should return an array of User instances." do
        User.find( :all ).each do | elt | 
          elt. should be_a_kind_of( User )  
        end
      end

      it "should return an array of length 2 when calling User.find( :all )" do
        User.find( :all ).length. should be_equal( 2 )
      end
            
    end # describe class methods
  
    describe "Find options" do

      it "should allow you to limit the number of search results returned." do
        User.find( :all, :limit => 2 ).length. should be_equal( 2 )
      end
      
      it "should allow you to search by a range." do
        underage_user = User.new
        underage_user.age = 17
        underage_user.save
        adult_user_ages = User.find( :all, :conditions => ['age > 18'] ).map{|u| u.age}
        adult_user_ages. should_not contain( 17 )
        adult_user_ages. should contain( 36 )
      end
      
      it "should allow you to specify the attributes that you're interested in to make your queries run faster." do
        pending
#        User.find( :all, :attributes => [:name, :id] ) ).first.id. should be_equal( 1 )
#        User.find( :all, :attributes => [:name, :id] ) ).first.name. should be_equal( 'David' )
#        User.find( :all, :attributes => [:name, :id] ) ).first.age. should be_nil        
      end
    end
  
    describe "Inter-model relationships" do

      before :each do
        class User 
          include TokyoRecord
          attributes :name
          has_many :post
        end
        @user = User.create( :name => 'David')

        class Post 
          include TokyoRecord
          attributes :title
          belongs_to :user
        end
        @post = Post.create( :title => 'Good morning', :user_id => 1 )
        @post2 = Post.create( :title => 'Good evening' )
        @post2.user = @user
        @post2.save
      end 
      
      it "should return an array when you call @user.posts." do
        @user.posts. should be_a_kind_of( Array )
      end
        
      it "should return an array of length 2 when you call @user.posts." do
        @user.posts.length. should be_equal( 2 )
      end

      it "should return an array of Post instances when you call @user.posts." do
        @user.posts.each do | post | 
          post. should be_an_instance_of( Post )
        end
      end

      it "should return an array whose 2nd element is a Post instance with the title of 'Good evening'." do
        @user.posts[1].title. should be_equal( 'Good evening' )
      end
    end    
  
    describe "when 2 attributes of the same model don't have differentnumbers of rows" do
  
      before :each do
        class User 
          include TokyoRecord
          attributes :name, :age
        end
        User.create( :name => 'David', :age => 36)
        User.create( :name => 'Makoto' ) # Note: The age databases don't have :age defined for Makoto.
      end
      
      it "should be able to create a new virtual row even though previous rows haven't been completely defined." do
        User.create( :name => 'Elvie', :age => 22)
        User.find( 3 ).name. should be_equal( 22 )
      end
      
      it "should be able to read an entire virtual table's row, even if no values are defined." do
        user = User.find_by_name( 'Makoto' )
        user.age.should be_nil
      end
      
      it "should be able to update an undefined value, even though it was null before." do
        user = User.find_by_name( 'Makto' )
        user.age = 25
        user.save
      end

      it "should be able to delete an entire row, even though some value hasn't been defined." do
        user = User.find_by_name( 'Makoto' )
        user.destroy
        user.age.should be_nil
        user.name.should be_nil
      end
  
    end
  
    describe "TokyoCabinet file closing abilities" do
      it "should close all file handles so that the data is not corrupted. " do
        TokyoRecord.close_all
        TokyoRecord. should be_completely_closed
      end
    end
=end 
