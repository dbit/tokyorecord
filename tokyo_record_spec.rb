require 'ftools'
require 'tokyo_record'
# If you're not used to doing tests with RSpec, try http://www.ibm.com/developerworks/web/library/wa-rspec/

describe TokyoRecord do
  
    before :each do
      class User < TokyoRecord
      end
      @user = User.new
    end
  
    after :all do
      # Remove all of the TC databases after all the tests are over.
      [ "User.id.fdb", 
        "Post.id.fdb",                     # `Id` attributes just keep track of the last insert id for each class.
                      "User.age.bdb", "User.age.fdb",         # Each non-`id` attribute has a bdb, for fast O(log n) searches by value, 
                      "User.name.bdb","User.name.fdb",        #   and an fdb for fast O(1) look-ups by id.
                      "Post.title.bdb","Post.title.fdb",
                      "Post.user_id.bdb","Post.user_id.fdb"
       ].each do |file|
        begin
          File.delete( file )
        rescue => e
          puts e
        end
      end
    end
    
    it "should not have any file handles when no properties are declared." do
      @user.file_handles.should be_empty
    end

    describe "Subclassed instances with properties called 'name' and 'age'" do
      
      before :each do
        class User < TokyoRecord
          attributes :name, :age
        end
        @user = User.new
      end
      
      it "should respond to the name= assignment operator." do
        @user.should respond_to?( 'name=' )
      end

      it "should respond to the age= assignment operator." do
        @user.should respond_to?( 'age=' )
      end
      
      it "should not have an tid (Tokyo Cabinet Id) before it is saved." do
        @user.tid.should be_null 
      end
      
      it "should not store the attribute in the database before you call save." do
        @user.name = 'David'
        User.find_by_name( 'David' ).should be_empty
      end

      it "should store the attribute in the database after you call save." do
        @user.name = 'David'
        @user.save
        User.find_by_name( 'David' ).should be_equal( 'David' )
      end

      it "should have a positive integer tid." do
        @user.name = 'David'
        @user.save
        @user.tid.should be > 0
      end
    end # end describe subclassed instances with a property called 'name'
  
    describe "Find methods" do

      before :each do
        class User < TokyoRecord
          attributes :name
        end
        @user = User.new
        @user.name = 'David'
        @user.save
      end
      
      it "should return an instance of the User class when searching for the record with an id of 1." do
        User.find( 1 ).should be_an_instance_of( User )
      end
      
      it "should return an array when calling User.find( :all )" do
        User.find( :all ).should be_a_kind_of( Array )
      end

      it "should return an array which contains an instance whose name is 'David' when calling find( :all )." do
        User.find( :all ).first.name.should equal( 'David' )
      end

      it "should return an instance of class User when calling find_by_name( 'David' )." do
        User.find_by_name( 'David' ).should be_an_instance_of( User )
      end
      
      it "should return an object when sending the 'name' message to it." do
        User.find_by_name( 'David' ).name.should be_equal( 'David' )
      end
      
      it "should return an array when calling User.find( :all )." do
        User.find( :all ).should be_a_kind_of( Array )
      end
            
    end # describe class methods
  
    describe "Find options" do
      it "should allow you to limit the number of search results returned." do
        User.find( :all, :limit => 2 ).length.should be_equal( 2 )
      end
      
      it "should allow you to search by a range." do
        underage_user = User.new
        underage_user.age = 17
        underage_user.save
        adult_user_ages = User.find( :all, :conditions => ['age > 18'] ).map{|u| u.age}
        adult_user_ages.should_not contain( 17 )
        adult_user_ages.should contain( 36 )
      end
      
      it "should allow you to specify the attributes that you're interested in to make your queries run faster." do
#        User.find( :all, :attributes => [:name, :id] ) ).first.id.should be_equal( 1 )
#        User.find( :all, :attributes => [:name, :id] ) ).first.name.should be_equal( 'David' )
#        User.find( :all, :attributes => [:name, :id] ) ).first.age.should be_nil        
      end
    end
  
    describe "Inter-model relationships" do

      before :each do
        class User < TokyoRecord
          attributes :name
          has_many :post
        end
        @user = User.new
        @user.name = 'David'
        @user.save
        class Post < TokyoRecord
          attributes :title
          belongs_to :user
        end
        @post = Post.new
        @post.title = 'Ohayou gozaimasu'
        @post.user = @user
        @post.save
        
        @post2 = Post.new
        @post2.title = 'Konban ha'
        @post2.user = @user
        @post2.save
      end 
      
      it "should return an array when you call @user.posts " do
        @user.posts.should be_a_kind_of( Array )
      end
        
      it "should return an array of length 2 when you call @user.posts " do
        @user.posts.length.should be_equal( 2 )
      end

      it "should return an array of Post instances when you call @user.posts " do
        @user.posts.each do | post | 
          post.should be_an_instance_of( Post )
        end
      end

      it "should return an array whose 2nd element is a Post instance with the title of 'Konban ha' " do
        @user.posts[1].title.should be_equal( 'Konban ha' )
      end
    end    
  
    describe "TokyoCabinet file closing abilities" do
      it "should close all file handles so that the data is not corrupted. " do
        TokyoRecord.close_all
        TokyoRecord.should be_completely_closed
      end
    end
    
end