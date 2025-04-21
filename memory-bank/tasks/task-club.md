# Club Module Tasks

- **Refactor DI**: Migrate `UserClubsCubit` creation to use `get_it`.
- **Define Functionality**: Clarify features needed beyond displaying the current club name (e.g., View club details, View member list for directors, Manage club settings for admins?).
- **API Endpoints**: Define and implement necessary endpoints in the NestJS API for fetching club details, member lists, etc.
- **Models**: Enhance `UserClubModel` or create new models (`ClubDetailModel`, `ClubMemberModel`) if needed.
- **Repository/Service**: Add methods to `UserService` or create a dedicated `ClubRepository/ClubService` for new API interactions.
- **State Management**: Implement new Blocs/Cubits if needed for managing club details or member lists.
- **Screens/UI**: Create necessary screens (e.g., `ClubDetailScreen`, `MemberListScreen`) and widgets.
- **Integrate**: Connect new screens/features where appropriate (e.g., from Home menu options for directors).
- **Testing**: Write Unit tests for `UserClubsCubit` and any new Blocs/Cubits. Write Widget tests for new screens/widgets. Write Integration tests for new repository/service methods. 