resource "aws_ec2_transit_gateway" "tgw" {
    description = "transit gateway demo"
    tags = merge(
        {
            "Name" = "twg-demo"
        },
        var.additional_tags,
    )
}


resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attachment" {
    count = length(module.vpc)
    subnet_ids = "${tolist(data.aws_subnet_ids.public[count.index].ids)}"
    vpc_id = "${module.vpc[count.index].vpc_id}"
    transit_gateway_id = "${aws_ec2_transit_gateway.tgw.id}"

    tags = merge(
        {
            "Name" = "${module.vpc[count.index].name}-transit-attachment"    
        },
        var.additional_tags,
    ) 
}

resource "aws_route" "twg-routes" {
    count = length(module.vpc)
    route_table_id = "${module.vpc[count.index].public_route_table_ids[0]}"
    destination_cidr_block = "10.0.0.0/8"
    transit_gateway_id = "${aws_ec2_transit_gateway.tgw.id}"

    depends_on = [
        aws_ec2_transit_gateway_vpc_attachment.tgw-attachment
    ]
}