Seller.create(name:"Ravi Kumar",description: Faker::Lorem::sentence,email: "ravi@gmail.com",user_id: User.first.id)
Product.create(title: "Rubic Cube",price: 100,description: Faker::Lorem::paragraph(sentence_count: 5),seller_id: Seller.first.id)
Product.create(title: "Head Phones",price: 100,description: Faker::Lorem::paragraph(sentence_count: 5),seller_id: Seller.first.id)