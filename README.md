
# GDS Data Innovation and AI Readiness Team Cloud Infrastructure Repository

<!--date_created: mon-18-may-2026-->
<!--date_updated: weds-27-may-2026-->


**Index**

 - [Get access to AIDR platform](#get-access-to-aidr-platform)

---

<!--There is no infrastructure in this repository. Code will be migrated once tested and necessary security parameters are in place-->

## Get access to the AIDR platform

**Some mandatory disclaimers**
* All users, with the exception of developer/engineer and admin users have access to the AIDR development environment.
* Developer/engineers and platform admins have access to all three environments. 
* Usage is tagged and tracked to ensure we can keep on top of resource use and spend per individual
* You will not have any rights to create iam roles on any account.
* Only `eu-west-2` region is permitted **by default**, without exception for anyone on the platform, including developer/engineer/platform admins. 

### Access the AIDR platform

0. If you are not currently a user on `gds-users` you will not be able to access the AIDR accounts

    **Request an AWS account from `gds-users`**
    
    **[https://engineering-enablement.gds-reliability.engineering/engineering/aws/users.html#requesting-a-new-aws-user](https://engineering-enablement.gds-reliability.engineering/engineering/aws/users.html#requesting-a-new-aws-user)**

> This is handled by another team in GDS/DSIT, you can contact engineering enablement on slack. The link above also has contact/escalation information. AIDR team cannot assist with this step. If you have issues with dsit email, contact EE team.


### Setup AWS CLI

> You must have MFA setup to use AWS. Once you have a `gds-users` user account on the organisation root:

1. [Login to AWS Console `eu-west-2`](https://eu-west-2.signin.aws.amazon.com/oauth?response_type=code&client_id=arn%3Aaws%3Asignin%3A%3A%3Aconsole%2Fcanvas&redirect_uri=https%3A%2F%2Feu-west-2.console.aws.amazon.com%2Fconsole%2Fhome%3Fca-oauth-flow-id%3D2e22%26hashArgs%3D%2523%26isauthcode%3Dtrue%26region%3Deu-west-2%26state%3DhashArgsFromTB_eu-west-2_6074d4ffbdeee16b&forceMobileLayout=0&forceMobileApp=0&code_challenge=sMKSP6mpJF8GyuCYUITXDoM1akiBy3asMJqP2U7AYpw&code_challenge_method=SHA-256)
2. Navigate to the top RHS: username -> Security Credentials
3. Setup MFA.
4. Make a note of these when you set up MFA and store in a safe place. You will need this to access AWS CLI: 
   
   - MFA_SERIAL/ARN
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY

5. Log in and out for changes to take effect. You should need to provide your MFA this time. 
    
> AWS accounts within AIDR team are assumed via the alphagov `gds-users` organisation/root account


### Assume role

0. You will be given a ROLE_ARN by the platform admin. Keep this in a safe place. 

> The following guidance assumes you have access to VSCODE

1. Install [`awscli`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. Configure your AWS profile(s)

> It is quite common to have more than one AWS profile for each role you are assuming

3. Your profile in `.config` will look like this; one corresponds to the ROOT `gds-users` account which you assume role into the AIDR platform, and the other corresponds to your role

```~.aws/~.config

# required by everyone
[profile gds-users]
region=eu-west-2
output=json
mfa_serial=<MFA_SERIAL>

# your specific profile
[profile gds-aidr-platform]
role_arn=<ROLE_ARN>
source_profile = gds-users
mfa_serial=<MFA_SERIAL>
region = eu-west-2
```

```~.aws/~.credentials

# required by everyone
[default]
aws_access_key_id=AWS_ACCESS_KEY_ID
aws_secret_access_key=AWS_SECRET_ACCESS_KEY_ID

# your specific profile
[profile gds-aidr-platform]
role_arn=<ROLE_ARN>
source_profile = gds-users
mfa_serial=<MFA_SERIAL>
region = eu-west-2
```

        
4. Assume your role via TerminalThe STS command looks like this. Copy-paste this block into a text file and update the values as required. `token-code` is your 6-digit MFA code. You can then copy the whole thing and paste into Terminal

```zsh
aws sts assume-role \
--role-arn "<ROLE_ARN" \
--role-session-name "TerraformLocalSession-AIDR" \
--serial-number "MFA_SERIAL" \
--token-code XXXXXX \ 
--profile gds-users \
```

5. Verify you are assumed into the role: `aws sts get-caller-identity`. The result should be something like this:

```zsh
    {
    "Credentials": {
        "AccessKeyId": "AWS_ACCESS_KEY_ID",
        "SecretAccessKey": "AWS_SECRET_ACCESS_KEY",
        "SessionToken": "",
        "Expiration": ""
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "",
        "Arn": "ROLE_ARN+LOCAL_SESSION_NAME"
    
```

---

---

<!--END-->