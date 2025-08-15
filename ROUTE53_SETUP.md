# Route 53 Setup Guide - Point Your Domain to Streamlit App

This guide shows you how to use Route 53 to direct traffic from your existing domain to your Streamlit app running on EC2.

## Prerequisites

- Your Streamlit app is running successfully on EC2 (accessible via `http://YOUR_EC2_IP:8501`)
- You have a domain name (either registered through Route 53 or elsewhere)
- Your EC2 instance has a public IP address

## Option 1: Domain Registered with Route 53 (Easiest)

If your domain is already registered with Route 53, you already have a hosted zone.

### Step 1: Find Your Hosted Zone
1. Go to **Route 53 Console** → **Hosted zones**
2. Click on your domain name (e.g., `yourdomain.com`)
3. You'll see existing DNS records

### Step 2: Create A Record for Streamlit App
1. Click **Create record**
2. **Record name**: Leave blank for root domain, or enter `streamlit` for subdomain
   - **Root domain**: `yourdomain.com` → Leave blank
   - **Subdomain**: `streamlit.yourdomain.com` → Enter `streamlit`
3. **Record type**: `A`
4. **Value**: Enter your EC2 instance's **public IP address**
5. **TTL**: `300` (5 minutes)
6. Click **Create records**

### Step 3: Access Your App
- **Root domain**: `http://yourdomain.com:8501`
- **Subdomain**: `http://streamlit.yourdomain.com:8501`

## Option 2: Domain Registered Elsewhere (GoDaddy, Namecheap, etc.)

If your domain is registered with another provider, you need to create a hosted zone in Route 53.

### Step 1: Create Hosted Zone in Route 53
1. Go to **Route 53 Console** → **Hosted zones** → **Create hosted zone**
2. **Domain name**: Enter your domain (e.g., `yourdomain.com`)
3. **Type**: `Public hosted zone`
4. Click **Create hosted zone**

### Step 2: Get Route 53 Name Servers
1. In your new hosted zone, you'll see 4 **NS (Name Server)** records
2. **Copy these 4 name servers** (they look like):
   ```
   ns-123.awsdns-12.com
   ns-456.awsdns-45.net
   ns-789.awsdns-78.org
   ns-012.awsdns-01.co.uk
   ```

### Step 3: Update Name Servers at Your Domain Registrar
1. **Log into your domain registrar** (GoDaddy, Namecheap, etc.)
2. **Find DNS/Name Server settings** for your domain
3. **Replace existing name servers** with the 4 Route 53 name servers
4. **Save changes** (can take 24-48 hours to propagate)

### Step 4: Create A Record in Route 53
1. Back in **Route 53** → Your hosted zone
2. Click **Create record**
3. **Record name**: Leave blank for root domain, or enter `streamlit` for subdomain
4. **Record type**: `A`
5. **Value**: Your EC2 instance's **public IP address**
6. **TTL**: `300`
7. Click **Create records**

## Option 3: Using Application Load Balancer (Recommended for Production)

For a more professional setup without port numbers in the URL:

### Step 1: Create Application Load Balancer
1. Go to **EC2 Console** → **Load Balancers** → **Create Load Balancer**
2. Choose **Application Load Balancer**
3. **Name**: `streamlit-alb`
4. **Scheme**: `Internet-facing`
5. **IP address type**: `IPv4`
6. **VPC**: Select your VPC
7. **Availability Zones**: Select at least 2 AZs
8. Click **Next**

### Step 2: Configure Security Group for ALB
1. **Create new security group** or select existing
2. **Inbound rules**:
   - **HTTP**: Port 80, Source: 0.0.0.0/0
   - **HTTPS**: Port 443, Source: 0.0.0.0/0 (if using SSL)

### Step 3: Configure Target Group
1. **Target type**: `Instances`
2. **Protocol**: `HTTP`
3. **Port**: `8501` (your Streamlit port)
4. **Health check path**: `/`
5. **Register targets**: Select your EC2 instance
6. **Port**: `8501`
7. Click **Create target group**

### Step 4: Complete Load Balancer Setup
1. **Listener**: HTTP:80 → Forward to your target group
2. Review and **Create load balancer**
3. **Copy the ALB DNS name** (e.g., `streamlit-alb-123456789.us-east-1.elb.amazonaws.com`)

### Step 5: Create Route 53 Alias Record
1. Go to **Route 53** → Your hosted zone → **Create record**
2. **Record name**: Leave blank or enter subdomain
3. **Record type**: `A`
4. **Alias**: Toggle **ON**
5. **Route traffic to**: `Alias to Application and Classic Load Balancer`
6. **Region**: Your AWS region
7. **Load balancer**: Select your ALB
8. Click **Create records**

### Step 6: Access Your App
- **Clean URL**: `http://yourdomain.com` (no port number!)
- **Subdomain**: `http://streamlit.yourdomain.com`

## Adding HTTPS/SSL (Optional but Recommended)

### Step 1: Request SSL Certificate
1. Go to **Certificate Manager** → **Request certificate**
2. **Domain names**: 
   - `yourdomain.com`
   - `*.yourdomain.com` (for subdomains)
3. **Validation method**: `DNS validation`
4. Click **Request**

### Step 2: Validate Certificate
1. **Add CNAME records** to Route 53 as shown in Certificate Manager
2. Wait for certificate status to become **Issued**

### Step 3: Add HTTPS Listener to ALB
1. Go to **EC2** → **Load Balancers** → Your ALB
2. **Listeners** tab → **Add listener**
3. **Protocol**: `HTTPS`
4. **Port**: `443`
5. **Default actions**: Forward to your target group
6. **Security policy**: `ELBSecurityPolicy-TLS-1-2-2017-01`
7. **Certificate**: Select your certificate
8. **Add**

### Step 4: Redirect HTTP to HTTPS (Optional)
1. **Edit** your HTTP:80 listener
2. **Default actions**: `Redirect`
3. **Protocol**: `HTTPS`
4. **Port**: `443`
5. **Status code**: `HTTP 301`

## Testing Your Setup

### Check DNS Propagation
```bash
# Check if your domain points to the right IP
nslookup yourdomain.com

# Check from different locations
dig yourdomain.com
```

### Test Your App
1. **Direct IP**: `http://YOUR_EC2_IP:8501` (should work)
2. **Domain**: `http://yourdomain.com:8501` (with A record)
3. **Clean URL**: `http://yourdomain.com` (with ALB)
4. **HTTPS**: `https://yourdomain.com` (with SSL)

## Troubleshooting

### Domain Not Resolving
- **Wait for DNS propagation** (up to 48 hours)
- **Check name servers** are correctly set at registrar
- **Verify A record** points to correct IP address

### App Not Loading
- **Check EC2 security group** allows traffic on port 8501
- **Verify Streamlit is running** on EC2 instance
- **Check ALB target health** if using load balancer

### SSL Issues
- **Certificate must be validated** before use
- **ALB security group** must allow HTTPS (port 443)
- **Check certificate domain names** match your domain

## Cost Considerations

- **Route 53 Hosted Zone**: $0.50/month per hosted zone
- **Route 53 Queries**: $0.40 per million queries
- **Application Load Balancer**: ~$16/month + data processing charges
- **SSL Certificate**: Free through AWS Certificate Manager

## Security Best Practices

1. **Use HTTPS** in production
2. **Restrict EC2 security group** to only allow traffic from ALB
3. **Enable ALB access logs** for monitoring
4. **Use WAF** for additional protection if needed

Choose the option that best fits your needs:
- **Option 1/2**: Simple setup, shows port in URL
- **Option 3**: Professional setup, clean URLs, better for production
