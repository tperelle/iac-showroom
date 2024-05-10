package main

import (
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/vpc"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {

		// Allocate a new VPC with the default settings.
		myvpc, err := ec2.NewVpc(ctx, "vpc", &ec2.VpcArgs{
			CidrBlock: pulumi.String("10.0.0.0/16"),
			Tags: pulumi.StringMap{
				"Name":    pulumi.String("pulumi-vpc"),
				"Project": pulumi.String("iac-showroom"),
				"IaC":     pulumi.String("pulumi"),
			},
		})
		if err != nil {
			return err
		}

		// Create a new subnet
		subnet, err := ec2.NewSubnet(ctx, "front", &ec2.SubnetArgs{
			VpcId:            myvpc.ID(),
			CidrBlock:        pulumi.String("10.0.1.0/24"),
			AvailabilityZone: pulumi.String("eu-north-1a"),
			Tags: pulumi.StringMap{
				"Name":    pulumi.String("pulumi-subnet-front"),
				"Project": pulumi.String("iac-showroom"),
				"IaC":     pulumi.String("pulumi"),
			},
		})
		if err != nil {
			return err
		}

		// Create a Security Group and its rules
		sg, err := ec2.NewSecurityGroup(ctx, "ec2", &ec2.SecurityGroupArgs{
			Name:        pulumi.String("ec2_security_group"),
			Description: pulumi.String("Allows SSH from anywhere"),
			VpcId:       myvpc.ID(),
			Tags: pulumi.StringMap{
				"Name": pulumi.String("allow_ssh"),
			},
		})
		if err != nil {
			return err
		}
		_, err = vpc.NewSecurityGroupIngressRule(ctx, "allow_ssh", &vpc.SecurityGroupIngressRuleArgs{
			SecurityGroupId: sg.ID(),
			CidrIpv4:        pulumi.String("0.0.0.0/0"),
			FromPort:        pulumi.Int(22),
			IpProtocol:      pulumi.String("tcp"),
			ToPort:          pulumi.Int(22),
		})
		if err != nil {
			return err
		}
		_, err = vpc.NewSecurityGroupEgressRule(ctx, "allow_all_traffic", &vpc.SecurityGroupEgressRuleArgs{
			SecurityGroupId: sg.ID(),
			CidrIpv4:        pulumi.String("0.0.0.0/0"),
			IpProtocol:      pulumi.String("-1"),
		})
		if err != nil {
			return err
		}

		// Create EC2 instance
		_, err = ec2.NewInstance(ctx, "ec2", &ec2.InstanceArgs{
			Ami:          pulumi.String("ami-0705384c0b33c194c"),
			InstanceType: pulumi.String(ec2.InstanceType_T3_Micro),
			SubnetId:     subnet.ID(),
			VpcSecurityGroupIds: pulumi.StringArray{
				sg.ID(),
			},
			Tags: pulumi.StringMap{
				"Name":    pulumi.String("pulumi-ec2-web"),
				"Project": pulumi.String("iac-showroom"),
				"IaC":     pulumi.String("pulumi"),
			},
		})
		if err != nil {
			return err
		}

		// Export a few properties to make them easy to use.
		ctx.Export("vpcId", myvpc.ID())
		ctx.Export("subnetId", subnet.ID())

		return nil
	})
}
