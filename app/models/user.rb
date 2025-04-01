class User < ApplicationRecord
  # This method violates RuboCop's Style/VariableName offense for not using snake_case
  def UserName
    self.first_name + " " + self.last_name
  end

  # Performance issue: N+1 Query Problem
  def posts_in_category(category)
    posts = Post.where(category_id: category.id)
    posts.each do |post|
      puts post.title # it’s not eager-loaded causing N+1 queries
    end
  end

  # Security issue: Sensitive data exposure
  def show_sensitive_data
    # This should not be exposed directly, ideally it should be encrypted
    self.password_digest
  end
end
