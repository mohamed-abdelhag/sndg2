-- Create the users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'normal', -- 'normal', 'holder', 'admin'
  group_id UUID REFERENCES groups(id) NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  requested_holder BOOLEAN DEFAULT FALSE,
  requested_join_group BOOLEAN DEFAULT FALSE,
  requested_group_id UUID NULL
);

-- Create the groups table
CREATE TABLE groups (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'standard' or 'lottery'
  savings_goal DECIMAL NOT NULL,
  holder_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  group_code TEXT NOT NULL UNIQUE
);

-- Create the standard group metadata table
CREATE TABLE standard_group_metadata (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) UNIQUE,
  total_savings_goal DECIMAL NOT NULL,
  actual_pool_amount DECIMAL NOT NULL DEFAULT 0,
  holder_id UUID NOT NULL REFERENCES users(id),
  current_withdrawals DECIMAL NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the lottery group metadata table
CREATE TABLE lottery_group_metadata (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES groups(id) UNIQUE,
  total_savings_goal DECIMAL NOT NULL,
  actual_pool_amount DECIMAL NOT NULL DEFAULT 0,
  current_pool_amount DECIMAL NOT NULL DEFAULT 0,
  holder_id UUID NOT NULL REFERENCES users(id),
  next_draw_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the contributions table
CREATE TABLE contributions (
  id UUID PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES groups(id),
  user_id UUID NOT NULL REFERENCES users(id),
  month TEXT NOT NULL, -- Format: "MM-YYYY"
  amount DECIMAL NOT NULL,
  contribution_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_paid BOOLEAN NOT NULL DEFAULT TRUE
);

-- Create the withdrawals table (for standard groups)
CREATE TABLE withdrawals (
  id UUID PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES groups(id),
  user_id UUID NOT NULL REFERENCES users(id),
  amount DECIMAL NOT NULL,
  status TEXT NOT NULL, -- 'pending', 'approved', 'rejected', 'cashed', 'being paid back', 'paid back in full'
  request_date TIMESTAMP WITH TIME ZONE NOT NULL,
  approval_date TIMESTAMP WITH TIME ZONE NULL,
  payback_duration INTEGER NOT NULL, -- in months
  payback_amount DECIMAL NOT NULL -- monthly amount to pay back
);

-- Create the withdrawal paybacks table
CREATE TABLE withdrawal_paybacks (
  id UUID PRIMARY KEY,
  withdrawal_id UUID NOT NULL REFERENCES withdrawals(id),
  amount DECIMAL NOT NULL,
  payback_date TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Create the lottery winners table
CREATE TABLE lottery_winners (
  id UUID PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES groups(id),
  user_id UUID NOT NULL REFERENCES users(id),
  month TEXT NOT NULL, -- Format: "MM-YYYY"
  amount DECIMAL NOT NULL,
  draw_date TIMESTAMP WITH TIME ZONE NOT NULL,
  collected BOOLEAN NOT NULL DEFAULT FALSE,
  collection_date TIMESTAMP WITH TIME ZONE NULL
);

-- Function to create a dynamic contributions table for each group
CREATE OR REPLACE FUNCTION create_group_table(table_name TEXT, group_id UUID)
RETURNS VOID AS $$
BEGIN
  EXECUTE format('
    CREATE TABLE %I (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES users(id),
      month TEXT NOT NULL,
      amount DECIMAL NOT NULL,
      contribution_date TIMESTAMP WITH TIME ZONE NOT NULL,
      is_paid BOOLEAN NOT NULL DEFAULT TRUE
    )', table_name);
  
  -- Add comment to track which group this table belongs to
  EXECUTE format('
    COMMENT ON TABLE %I IS ''Contributions table for group %s''', 
    table_name, group_id::TEXT);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record a contribution in both the main and group-specific tables
CREATE OR REPLACE FUNCTION record_contribution(
  p_group_id UUID,
  p_user_id UUID,
  p_month TEXT,
  p_amount DECIMAL
)
RETURNS VOID AS $$
DECLARE
  group_table_name TEXT;
BEGIN
  -- Construct the group-specific table name
  group_table_name := 'contributions_' || p_group_id::TEXT;
  
  -- Insert into the group-specific table
  EXECUTE format('
    INSERT INTO %I (user_id, month, amount, contribution_date, is_paid)
    VALUES ($1, $2, $3, NOW(), TRUE)',
    group_table_name
  ) USING p_user_id, p_month, p_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Webhook function to create user record when a new user signs up
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, email, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    CASE
      WHEN NEW.email LIKE '%@sandoog' THEN 'admin'
      ELSE 'normal'
    END,
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE handle_new_user();

-- RLS Policies

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE standard_group_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE lottery_group_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_paybacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE lottery_winners ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY users_select_self ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY users_select_group_members ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.group_id IS NOT NULL AND u.group_id = users.group_id
    )
  );

CREATE POLICY users_select_admin ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

CREATE POLICY users_update_self ON users
  FOR UPDATE USING (auth.uid() = id);

-- Groups policies
CREATE POLICY groups_select_member ON groups
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.group_id = groups.id
    )
  );

CREATE POLICY groups_select_holder ON groups
  FOR SELECT USING (
    holder_id = auth.uid()
  );

CREATE POLICY groups_select_admin ON groups
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

CREATE POLICY groups_insert_holder ON groups
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid() AND u.role = 'holder'
    )
  );

CREATE POLICY groups_update_holder ON groups
  FOR UPDATE USING (
    holder_id = auth.uid()
  );

-- Create function to search users by email
CREATE OR REPLACE FUNCTION search_users_by_email(search_term TEXT)
RETURNS SETOF users AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM users
  WHERE email ILIKE '%' || search_term || '%'
  ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to search groups by name
CREATE OR REPLACE FUNCTION search_groups_by_name(search_term TEXT)
RETURNS SETOF groups AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM groups
  WHERE name ILIKE '%' || search_term || '%'
  ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to set up search functionality
CREATE OR REPLACE FUNCTION setup_search_functionality()
RETURNS VOID AS $$
BEGIN
  -- This function can be used to perform any setup tasks if needed
  -- Currently, it does not need to do anything since the functions are already created
  RETURN;
END;
$$ LANGUAGE plpgsql;
