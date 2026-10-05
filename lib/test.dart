import 'package:flutter/material.dart';

class ProductScreen extends StatefulWidget {
  final int initialPrice;
  final bool isDiscounted;

  const ProductScreen({super.key, required this.initialPrice, this.isDiscounted = false});

  @override
  State<ProductScreen> createState() => _ProductScreenState();

}

class _ProductScreenState extends State<ProductScreen> {
  int? finalPrice;
  List<String> products = ["shoes", "textile", "trouser", "jackets", "hoods"];
  List<String> selectedProducts = [];
  var areDiscounted = [];
 late int price = widget.initialPrice;
 late bool discount = widget.isDiscounted;


  @override
  void initState() {
    super.initState();
   price = widget.initialPrice;
   selectedProducts = products;
   discount = widget.isDiscounted;
  }

  void selectedItems(String item){
    setState(() {

    if(item == "shoes") {
      price = 750;
    } else if(item == "trouser") {
      price = 700;
    } else if(item == "hood"){
      price = 400;
    } else {
      price = 3000;
    }
    });
  }



  void discountedPrice() {
    setState(() {
    if(discount) {
      finalPrice = (0.5 * price).toInt();
    } else {
      finalPrice = price;
    }
    });
  }



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}