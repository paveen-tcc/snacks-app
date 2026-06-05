type MenuCatalogSection = {
  category: string;
  emoji: string;
  items: Array<{
    name: string;
    isVeg: boolean;
    servingSize: string;
    emoji: string;
  }>;
};

const menuCatalogSections: MenuCatalogSection[] = [
  {
    category: 'Pizza',
    emoji: '🍕',
    items: [
      { name: 'Smiley Veg Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80' },
      { name: 'Mushroom Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?auto=format&fit=crop&w=400&q=80' },
      { name: 'Veg Peri Peri Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?auto=format&fit=crop&w=400&q=80' },
      { name: 'Healthy Paneer Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1506354666786-959d6d497f1a?auto=format&fit=crop&w=400&q=80' },
      { name: 'Mushroom Peri Peri Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?auto=format&fit=crop&w=400&q=80' },
      { name: 'Paneer Peri Peri Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Pizza', isVeg: false, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Peri Peri Pizza', isVeg: false, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80' },
      { name: 'Baby Corn Peri Peri Pizza', isVeg: true, servingSize: '1 Pizza', emoji: 'https://images.unsplash.com/photo-1544982503-9f984c14501a?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Sandwich',
    emoji: '🥪',
    items: [
      { name: 'Veg Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1539252554453-80ab65ce3586?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chocolate Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?auto=format&fit=crop&w=400&q=80' },
      { name: 'Veg Peri Peri Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1621852004158-f3bc188ace2d?auto=format&fit=crop&w=400&q=80' },
      { name: 'Mushroom Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1540713434306-585de5375c53?auto=format&fit=crop&w=400&q=80' },
      { name: 'Veg Paneer Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?auto=format&fit=crop&w=400&q=80' },
      { name: 'Mushroom Peri Peri Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?auto=format&fit=crop&w=400&q=80' },
      { name: 'Veg Paneer Peri Peri Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1540713434306-585de5375c53?auto=format&fit=crop&w=400&q=80' },
      { name: 'Baby Corn Peri Peri Sandwich', isVeg: true, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Sandwich', isVeg: false, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1619096303193-36c452ba95e9?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Peri Peri Sandwich', isVeg: false, servingSize: '1 Sandwich', emoji: 'https://images.unsplash.com/photo-1627308595229-7830a5c91f9f?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Burger',
    emoji: '🍔',
    items: [
      { name: 'Veg Cheese Burger', isVeg: true, servingSize: '1 Burger', emoji: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=400&q=80' },
      { name: 'Allo Tikra Chesse Burger', isVeg: true, servingSize: '1 Burger', emoji: 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=400&q=80' },
      { name: 'Veg Jumbo Burger', isVeg: true, servingSize: '1 Burger', emoji: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80' },
      { name: 'Mushroom Burger', isVeg: true, servingSize: '1 Burger', emoji: 'https://images.unsplash.com/photo-1585238342024-78d387f4a707?auto=format&fit=crop&w=400&q=80' },
      { name: 'Healthy Paneer Burger', isVeg: true, servingSize: '1 Burger', emoji: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Cheese Burger', isVeg: false, servingSize: '1 Burger', emoji: 'https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Fries',
    emoji: '🍟',
    items: [
      { name: 'Smiley', isVeg: true, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=400&q=80' },
      { name: 'Allo Tikra', isVeg: true, servingSize: '2 Pcs', emoji: 'https://images.unsplash.com/photo-1598182126853-0e86b2490c13?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chilli Garlic Potato', isVeg: true, servingSize: '10 Pcs', emoji: 'https://images.unsplash.com/photo-1618412613524-74737d2f9ef2?auto=format&fit=crop&w=400&q=80' },
      { name: 'French Fries', isVeg: true, servingSize: '160 Grm', emoji: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=400&q=80' },
      { name: 'Potato Wedges', isVeg: true, servingSize: '160 Grm', emoji: 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=400&q=80' },
      { name: 'Cheese Corn Nugget', isVeg: true, servingSize: '6 Pcs', emoji: 'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Roll',
    emoji: '🌯',
    items: [
      { name: 'Veg Roll', isVeg: true, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1626700051175-6518c4793f4f?auto=format&fit=crop&w=400&q=80' },
      { name: 'Schezwan Roll', isVeg: true, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1607532941433-304659e8198a?auto=format&fit=crop&w=400&q=80' },
      { name: 'Paneer Roll', isVeg: true, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1618414502598-a28b030b4274?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Roll', isVeg: false, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1642686139755-667f62e6e877?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Momos',
    emoji: '🥟',
    items: [
      { name: 'Veg Momos', isVeg: true, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=400&q=80' },
      { name: 'Schezwan Momos', isVeg: true, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1625220194771-7ebdede5f909?auto=format&fit=crop&w=400&q=80' },
      { name: 'Paneer Momos', isVeg: true, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Momos', isVeg: false, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Fingers Fried',
    emoji: '🍗',
    items: [
      { name: 'Veg Fingers', isVeg: true, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1626201726752-6c359a5dcf37?auto=format&fit=crop&w=400&q=80' },
      { name: 'Paneer Fingers', isVeg: true, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80' },
      { name: 'Schezwan Fingers', isVeg: true, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1608897013039-887f21d8c804?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Fingers', isVeg: false, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Chicken Varieties',
    emoji: '🍗',
    items: [
      { name: 'Spicy Chicken Wings', isVeg: false, servingSize: '3 Pcs', emoji: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Spicy Snackers', isVeg: false, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Lollipop', isVeg: false, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Nuggets', isVeg: false, servingSize: '5 Pcs', emoji: 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?auto=format&fit=crop&w=400&q=80' },
      { name: 'Crab Lollipop', isVeg: false, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1534080564583-6be75777b70a?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Samosa',
    emoji: '🥟',
    items: [
      { name: 'Schezwan Samosa', isVeg: true, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&w=400&q=80' },
      { name: 'Chicken Samosa', isVeg: false, servingSize: '4 Pcs', emoji: 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&w=400&q=80' },
    ],
  },
  {
    category: 'Drinks',
    emoji: '🥤',
    items: [
      { name: 'Tea', isVeg: true, servingSize: '1 Cup', emoji: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80' },
      { name: 'Coffee', isVeg: true, servingSize: '1 Cup', emoji: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=400&q=80' },
      { name: 'Boost', isVeg: true, servingSize: '1 Cup', emoji: 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?auto=format&fit=crop&w=400&q=80' },
    ],
  },
];

export const menuSnackCatalog = menuCatalogSections.flatMap((section, sectionIndex) =>
  section.items.map((item, itemIndex) => ({
    name: item.name,
    isVeg: item.isVeg,
    servingSize: item.servingSize,
    category: section.category,
    emoji: item.emoji,
    sortOrder: sectionIndex * 100 + itemIndex + 1,
  })),
);
