type MenuCatalogSection = {
  category: string;
  emoji: string;
  items: Array<{
    name: string;
    description: string;
    isVeg: boolean;
    servingSize: string;
  }>;
};

const menuCatalogSections: MenuCatalogSection[] = [
  {
    category: 'Pizza',
    emoji: '🍕',
    items: [
      { name: 'Smiley Veg Pizza', description: 'Cheesy veggie pizza slices', isVeg: true, servingSize: '1 Pizza' },
      { name: 'Mushroom Pizza', description: 'Loaded mushroom pizza slices', isVeg: true, servingSize: '1 Pizza' },
      { name: 'Veg Peri Peri Pizza', description: 'Spicy peri peri veg pizza', isVeg: true, servingSize: '1 Pizza' },
      { name: 'Healthy Paneer Pizza', description: 'Paneer topped cheesy pizza', isVeg: true, servingSize: '1 Pizza' },
      { name: 'Mushroom Peri Peri Pizza', description: 'Mushroom pizza with peri peri', isVeg: true, servingSize: '1 Pizza' },
      { name: 'Paneer Peri Peri Pizza', description: 'Paneer pizza with peri peri', isVeg: true, servingSize: '1 Pizza' },
      { name: 'Chicken Pizza', description: 'Classic chicken pizza slices', isVeg: false, servingSize: '1 Pizza' },
      { name: 'Chicken Peri Peri Pizza', description: 'Chicken pizza with peri peri', isVeg: false, servingSize: '1 Pizza' },
      { name: 'Baby Corn Peri Peri Pizza', description: 'Baby corn spicy pizza', isVeg: true, servingSize: '1 Pizza' },
    ],
  },
  {
    category: 'Sandwich',
    emoji: '🥪',
    items: [
      { name: 'Veg Sandwich', description: 'Fresh mixed veggie sandwich', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Chocolate Sandwich', description: 'Sweet chocolate filled sandwich', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Veg Peri Peri Sandwich', description: 'Veg sandwich with peri peri', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Mushroom Sandwich', description: 'Toasted mushroom sandwich bites', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Veg Paneer Sandwich', description: 'Paneer stuffed veg sandwich', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Mushroom Peri Peri Sandwich', description: 'Spicy mushroom sandwich toast', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Veg Paneer Peri Peri Sandwich', description: 'Paneer sandwich with peri peri', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Baby Corn Peri Peri Sandwich', description: 'Baby corn spicy sandwich', isVeg: true, servingSize: '1 Sandwich' },
      { name: 'Chicken Sandwich', description: 'Classic chicken toasted sandwich', isVeg: false, servingSize: '1 Sandwich' },
      { name: 'Chicken Peri Peri Sandwich', description: 'Chicken sandwich with peri peri', isVeg: false, servingSize: '1 Sandwich' },
    ],
  },
  {
    category: 'Burger',
    emoji: '🍔',
    items: [
      { name: 'Veg Cheese Burger', description: 'Cheesy veg burger stack', isVeg: true, servingSize: '1 Burger' },
      { name: 'Allo Tikra Chesse Burger', description: 'Aloo tikka cheesy burger', isVeg: true, servingSize: '1 Burger' },
      { name: 'Veg Jumbo Burger', description: 'Loaded jumbo veg burger', isVeg: true, servingSize: '1 Burger' },
      { name: 'Mushroom Burger', description: 'Juicy mushroom burger stack', isVeg: true, servingSize: '1 Burger' },
      { name: 'Healthy Paneer Burger', description: 'Paneer patty burger stack', isVeg: true, servingSize: '1 Burger' },
      { name: 'Chicken Cheese Burger', description: 'Chicken burger with cheese', isVeg: false, servingSize: '1 Burger' },
    ],
  },
  {
    category: 'Fries',
    emoji: '🍟',
    items: [
      { name: 'Smiley', description: 'Crispy smiley potato bites', isVeg: true, servingSize: '4 Pcs' },
      { name: 'Allo Tikra', description: 'Spiced potato tikka bites', isVeg: true, servingSize: '2 Pcs' },
      { name: 'Chilli Garlic Potato', description: 'Chilli garlic potato bites', isVeg: true, servingSize: '10 Pcs' },
      { name: 'French Fries', description: 'Classic salted french fries', isVeg: true, servingSize: '160 Grm' },
      { name: 'Potato Wedges', description: 'Seasoned crispy potato wedges', isVeg: true, servingSize: '160 Grm' },
      { name: 'Cheese Corn Nugget', description: 'Cheesy corn nugget bites', isVeg: true, servingSize: '6 Pcs' },
    ],
  },
  {
    category: 'Roll',
    emoji: '🌯',
    items: [
      { name: 'Veg Roll', description: 'Stuffed veggie roll bites', isVeg: true, servingSize: '4 Pcs' },
      { name: 'Schezwan Roll', description: 'Spicy schezwan roll bites', isVeg: true, servingSize: '4 Pcs' },
      { name: 'Paneer Roll', description: 'Paneer filled roll bites', isVeg: true, servingSize: '4 Pcs' },
      { name: 'Chicken Roll', description: 'Chicken filled roll bites', isVeg: false, servingSize: '4 Pcs' },
    ],
  },
  {
    category: 'Momos',
    emoji: '🥟',
    items: [
      { name: 'Veg Momos', description: 'Steamed mixed veggie momos', isVeg: true, servingSize: '5 Pcs' },
      { name: 'Schezwan Momos', description: 'Spicy schezwan momos bites', isVeg: true, servingSize: '5 Pcs' },
      { name: 'Paneer Momos', description: 'Paneer stuffed steamed momos', isVeg: true, servingSize: '5 Pcs' },
      { name: 'Chicken Momos', description: 'Chicken stuffed steamed momos', isVeg: false, servingSize: '5 Pcs' },
    ],
  },
  {
    category: 'Fingers Fried',
    emoji: '🍗',
    items: [
      { name: 'Veg Fingers', description: 'Crispy veggie finger bites', isVeg: true, servingSize: '5 Pcs' },
      { name: 'Paneer Fingers', description: 'Crispy paneer finger bites', isVeg: true, servingSize: '5 Pcs' },
      { name: 'Schezwan Fingers', description: 'Spicy schezwan finger bites', isVeg: true, servingSize: '5 Pcs' },
      { name: 'Chicken Fingers', description: 'Crispy chicken finger bites', isVeg: false, servingSize: '5 Pcs' },
    ],
  },
  {
    category: 'Chicken Varieties',
    emoji: '🍗',
    items: [
      { name: 'Spicy Chicken Wings', description: 'Spicy crispy chicken wings', isVeg: false, servingSize: '3 Pcs' },
      { name: 'Chicken Spicy Snackers', description: 'Spicy chicken snacker bites', isVeg: false, servingSize: '4 Pcs' },
      { name: 'Chicken Lollipop', description: 'Crispy chicken lollipop bites', isVeg: false, servingSize: '4 Pcs' },
      { name: 'Chicken Nuggets', description: 'Crispy chicken nugget bites', isVeg: false, servingSize: '5 Pcs' },
      { name: 'Crab Lollipop', description: 'Crispy crab lollipop bites', isVeg: false, servingSize: '4 Pcs' },
    ],
  },
  {
    category: 'Samosa',
    emoji: '🥟',
    items: [
      { name: 'Schezwan Samosa', description: 'Spicy schezwan samosa bites', isVeg: true, servingSize: '4 Pcs' },
      { name: 'Chicken Samosa', description: 'Chicken filled samosa bites', isVeg: false, servingSize: '4 Pcs' },
    ],
  },
];

export const menuSnackCatalog = menuCatalogSections.flatMap((section, sectionIndex) =>
  section.items.map((item, itemIndex) => ({
    ...item,
    category: section.category,
    emoji: section.emoji,
    sortOrder: sectionIndex * 100 + itemIndex + 1,
  })),
);
