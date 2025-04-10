# Sandoog Supabase Project Details

## Project Information
- **Project Name:** Sandoog
- **Project ID:** cvpvhrsevgmgktyldtro
- **Region:** ap-southeast-1
- **API URL:** https://cvpvhrsevgmgktyldtro.supabase.co
- **Database:** PostgreSQL
- **Database Version:** 15.1
- **Database Port:** 5432

## Database Structure

### Tables

#### users
```sql
CREATE TABLE public.users (
    id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'normal',
    group_id UUID REFERENCES public.groups(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    requested_holder BOOLEAN DEFAULT false,
    requested_join_group BOOLEAN DEFAULT false,
    requested_group_id UUID REFERENCES public.groups(id)
);
```

#### groups
```sql
CREATE TABLE public.groups (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    savings_goal DECIMAL NOT NULL,
    holder_id UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    group_code TEXT NOT NULL UNIQUE
);
```

#### standard_group_metadata
```sql
CREATE TABLE public.standard_group_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES public.groups(id) NOT NULL UNIQUE,
    total_savings_goal DECIMAL NOT NULL,
    actual_pool_amount DECIMAL NOT NULL DEFAULT 0,
    holder_id UUID REFERENCES public.users(id) NOT NULL,
    current_withdrawals DECIMAL NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

#### lottery_group_metadata
```sql
CREATE TABLE public.lottery_group_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES public.groups(id) NOT NULL UNIQUE,
    total_savings_goal DECIMAL NOT NULL,
    actual_pool_amount DECIMAL NOT NULL DEFAULT 0,
    holder_id UUID REFERENCES public.users(id) NOT NULL,
    next_draw_date TIMESTAMP WITH TIME ZONE NOT NULL,
    current_pool_amount DECIMAL NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

#### withdrawals
```sql
CREATE TABLE public.withdrawals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES public.groups(id) NOT NULL,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    amount DECIMAL NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    request_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    approval_date TIMESTAMP WITH TIME ZONE,
    payback_duration INTEGER,
    payback_amount DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

#### user_emails
```sql
CREATE TABLE public.user_emails (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    is_admin BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### Stored Procedures

#### create_group_table
```sql
CREATE OR REPLACE FUNCTION create_group_table(table_name TEXT, group_id UUID)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('
        CREATE TABLE public.%I (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            month INTEGER NOT NULL,
            year INTEGER NOT NULL,
            user_id UUID REFERENCES public.users(id) NOT NULL,
            amount DECIMAL NOT NULL DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE(month, year, user_id)
        )', 'contributions_' || group_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### get_all_users (Admin Function)
```sql
CREATE OR REPLACE FUNCTION get_all_users()
RETURNS SETOF public.users AS $$
BEGIN
  -- Check if the user is an admin
  IF EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN QUERY SELECT * FROM public.users;
  ELSE
    RAISE EXCEPTION 'Permission denied: Only admins can call this function';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### get_holder_requests (Admin Function)
```sql
CREATE OR REPLACE FUNCTION get_holder_requests()
RETURNS SETOF public.users AS $$
BEGIN
  -- Check if the user is an admin
  IF EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN QUERY SELECT * FROM public.users WHERE requested_holder = true;
  ELSE
    RAISE EXCEPTION 'Permission denied: Only admins can call this function';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### create_user_record
```sql
CREATE OR REPLACE FUNCTION public.create_user_record(user_id UUID, user_email TEXT, user_role TEXT)
RETURNS VOID AS $$
BEGIN
    -- Create user record in public.users if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = user_id) THEN
        INSERT INTO public.users (id, email, role, created_at, updated_at, requested_holder, requested_join_group)
        VALUES (user_id, user_email, user_role, NOW(), NOW(), false, false);
    END IF;
    
    -- Ensure user is in user_emails
    IF NOT EXISTS (SELECT 1 FROM public.user_emails WHERE id = user_id) THEN
        INSERT INTO public.user_emails (id, email, is_admin, created_at)
        VALUES (user_id, user_email, user_email LIKE '%@sandoog', NOW());
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### handle_new_auth_user
```sql
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Determine role based on email domain
    IF NEW.email LIKE '%@sandoog%' THEN
        user_role := 'admin';
    ELSE
        user_role := 'normal';
    END IF;
    
    -- Insert into public.users if not exists
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
        INSERT INTO public.users (
            id, 
            email,
            role,
            created_at,
            updated_at,
            requested_holder,
            requested_join_group
        ) VALUES (
            NEW.id,
            NEW.email,
            user_role,
            COALESCE(NEW.created_at, NOW()),
            COALESCE(NEW.updated_at, NOW()),
            false,
            false
        );
    END IF;
    
    -- Insert into user_emails
    IF NOT EXISTS (SELECT 1 FROM public.user_emails WHERE id = NEW.id) THEN
        INSERT INTO public.user_emails (
            id,
            email,
            is_admin,
            created_at
        ) VALUES (
            NEW.id,
            NEW.email,
            NEW.email LIKE '%@sandoog%',
            COALESCE(NEW.created_at, NOW())
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### ensure_user_record
```sql
CREATE OR REPLACE FUNCTION public.ensure_user_record()
RETURNS TRIGGER AS $$
BEGIN
  -- If user doesn't exist in public.users, create them
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
    INSERT INTO public.users (
      id, 
      email, 
      role, 
      created_at, 
      updated_at, 
      requested_holder, 
      requested_join_group
    ) 
    VALUES (
      NEW.id, 
      NEW.email, 
      CASE 
        WHEN NEW.email LIKE '%@sandoog%' THEN 'admin'
        ELSE 'normal' 
      END,
      NOW(), 
      NOW(), 
      false, 
      false
    );
  END IF;
  
  -- Also make sure they exist in user_emails
  IF NOT EXISTS (SELECT 1 FROM public.user_emails WHERE id = NEW.id) THEN
    INSERT INTO public.user_emails (
      id,
      email,
      is_admin,
      created_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      NEW.email LIKE '%@sandoog%',
      NOW()
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Row Level Security Policies

#### users table RLS
```sql
-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own data" 
ON public.users 
FOR SELECT 
USING (auth.uid() = id);

CREATE POLICY "Admins can read all users" 
ON public.users 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Admins can update all users" 
ON public.users 
FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

CREATE POLICY "Holders can read users in their groups" 
ON public.users 
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'holder'
  ) AND (
    group_id IN (
      SELECT group_id FROM public.users 
      WHERE id = auth.uid() AND role = 'holder'
    )
  )
);
```

### Existing Data
- **Admin User:** admin1@sandoog.com
- **Current Tables:** users, groups, standard_group_metadata, lottery_group_metadata, withdrawals, and contribution tables

### Development Notes
- The application handles authentication through Supabase Auth
- Dynamic contribution tables are created per group using a stored procedure
- Admin users are identified by emails ending with '@sandoog'
- Security definer functions are used to safely bypass RLS for admin operations
- Row Level Security policies control access to data based on user roles

