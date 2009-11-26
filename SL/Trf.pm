package Trf;

sub transfer_details {
   my ($self, $myconfig, $form) = @_;

   $form->{trfdate} = $form->{transdate};
   $form->{trfdescription} = $form->{description};
   ($form->{from_warehouse}) = split(/--/, $form->{from_warehouse});
   ($form->{to_warehouse}) = split(/--/, $form->{to_warehouse});
   ($form->{department}) = split(/--/, $form->{department});

   my $runningnumber = 1;
   my $linetotal = 0;
   for $i (1 .. $form->{rowcount} - 1){
      push(@{ $form->{runningnumber} }, $runningnumber++);
      push (@{ $form->{number} }, $form->{"partnumber_$i"});
      push (@{ $form->{descrip} }, $form->{"description_$i"});
      push (@{ $form->{description} }, $form->{"description_$i"});
      push (@{ $form->{unit} }, $form->{"unit_$i"});
      push (@{ $form->{qty} }, $form->format_amount($myconfig, $form->{"qty_$i"}, 2));
      push (@{ $form->{cost} }, $form->format_amount($myconfig, $form->{"cost_$i"}, 2));
      $linetotal = $form->{"qty_$i"} * $form->{"cost_$i"};
      $form->{trftotal} += $linetotal;
      push (@{ $form->{linetotal} }, $form->format_amount($myconfig, $linetotal, 2));
   }
   $form->{trftotal} = $form->format_amount($myconfig, $form->{trftotal}, 2);
}

sub retrieve_item {
  my ($self, $myconfig, $form) = @_;
  
  my $dbh = $form->dbconnect($myconfig);
  my $i = $form->{rowcount};
  my $var;
 
  my $where = "WHERE p.obsolete = '0' AND p.income_accno_id IS NOT NULL";
  if ($form->{"partnumber_$i"} ne ""){
    $var = $form->like(lc $form->{"partnumber_$i"});
    $where .= " AND LOWER(p.partnumber) LIKE '$var'";
  }
  if ($form->{"description_$i"} ne ""){
    $var = $form->like(lc $form->{"description_$i"});
    $where .= " AND LOWER(p.description) LIKE '$var'";
  }
  if ($form->{"partsgroup_$i"}){
     my ($null, $partsgroup_id) = split(/--/, $form->{"partsgroup_$i"});
     $partsgroup_id *= 1;
     $where .= " AND p.partsgroup_id = $partsgroup_id";
  }
  if ($form->{"description_$i"} ne ""){
    $where .= " ORDER BY 3";
  } else {
    $where .= " ORDER BY 2";
  }
  my $query = qq|SELECT p.id, p.partnumber, p.description, p.sellprice,
		p.listprice, p.lastcost, p.unit, p.assembly, p.onhand, 
		p.notes AS itemnotes
		FROM parts p
		$where|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     push @{ $form->{item_list} }, $ref;
  }
  $sth->finish;
  $dbh->disconnect;
}

1;

